import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
// ignore: unused_import
import '../../services/privacy_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import '../../services/chat_service.dart';
import '../../services/translation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../chat/chat_screen.dart';
import 'admin_extra_tabs.dart';
import 'dart:typed_data';
import '../../services/order_excel_service.dart';
import '../../utils/web_utils.dart' if (dart.library.html) '../../utils/web_utils_html.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminScreen extends StatefulWidget {
  final int initialTab;
  const AdminScreen({super.key, this.initialTab = 0});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _orderFilterIdx = 0;
  String? _sectionSelectedProductId; // 섹션관리 탭 선택된 상품
  // 동적 섹션 목록 (추가/삭제 가능)
  final List<Map<String, dynamic>> _customSections = [
    {'key': 's1', 'label': '섹션 1', 'title': '메인 배너', 'icon': Icons.star_rounded},
    {'key': 's2', 'label': '섹션 2', 'title': '소재 및 기술', 'icon': Icons.science_rounded},
    {'key': 's3', 'label': '섹션 3', 'title': '스마트 포켓', 'icon': Icons.shopping_bag_rounded},
    {'key': 's5', 'label': '섹션 5', 'title': '골지 원단 색상', 'icon': Icons.palette_rounded},
    {'key': 's6', 'label': '섹션 6', 'title': '사이즈 차트', 'icon': Icons.table_chart_rounded},
  ];
  final Set<String> _selectedProductIds = {};
  final Set<String> _selectedOrderIds = {};   // 주문관리 선택
  final Set<String> _selectedMemberIds = {};  // 회원관리 선택
  String _productSearchQuery = '';
  String _orderSearchQuery = '';
  String _memberSearchQuery = '';
  String _productCategoryFilter = '전체';

  static const _orderFilters = ['전체', '주문 대기', '주문 확인', '제작/준비 중', '배송 중', '배송 완료', '주문 취소'];

  // ── 알림 설정 상태
  String _adminPhone = '';
  bool _notifyNewChat = true;
  bool _notifyNewOrder = true;
  bool _notifyChatSms = false;
  final int _pendingChatCount = 0;

  // ── 채팅 세션 목록 (관리자 뷰 - Firestore로 대체됨)
  // ignore: unused_field
  final List<Map<String, dynamic>> _chatSessions = [
    {
      'id': 'cs_001',
      'user': '김민준',
      'lastMsg': '주문 상태 확인',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'unread': 2,
      'messages': <ChatMessage>[
        ChatMessage(text: '주문 상태 확인', originalText: '주문 상태 확인', isUser: true, time: DateTime.now().subtract(const Duration(minutes: 5))),
        ChatMessage(text: '주문 번호를 알려주시면 주문 상태를 확인해 드리겠습니다.', isUser: false, time: DateTime.now().subtract(const Duration(minutes: 4))),
      ],
    },
    {
      'id': 'cs_002',
      'user': 'Battulga',
      'lastMsg': 'Хэмжээний зөвлөмж',
      'originalLastMsg': '사이즈 추천',
      'time': DateTime.now().subtract(const Duration(minutes: 23)),
      'unread': 1,
      'messages': <ChatMessage>[
        ChatMessage(
          text: 'Хэмжээний зөвлөмж',
          originalText: '사이즈 추천',
          isUser: true,
          time: DateTime.now().subtract(const Duration(minutes: 23)),
        ),
      ],
    },
    {
      'id': 'cs_003',
      'user': '山田太郎',
      'lastMsg': '交換・返品申請',
      'originalLastMsg': '교환/환불 신청',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'unread': 0,
      'messages': <ChatMessage>[
        ChatMessage(
          text: '交換・返品申請',
          originalText: '교환/환불 신청',
          isUser: true,
          time: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ChatMessage(text: '교환/환불은 수령 후 7일 이내 가능합니다.', isUser: false, time: DateTime.now().subtract(const Duration(minutes: 55))),
      ],
    },
  ];

  // 배너 관리용 상태 변수
  final List<Map<String, dynamic>> _bannerItems = [
    {'title': 'NEW SEASON', 'tag': 'NEW', 'active': true, 'order': 1},
    {'title': 'BEST SELLER', 'tag': 'BEST', 'active': true, 'order': 2},
    {'title': 'GROUP ORDER', 'tag': 'GROUP', 'active': true, 'order': 3},
    {'title': 'CUSTOM FIT', 'tag': 'CUSTOM', 'active': false, 'order': 4},
  ];

  // ── 색상 관리 상태
  final List<Map<String, dynamic>> _colorItems = [
    {'id': 'c1', 'name': '블랙', 'hexCode': '#1A1A1A', 'category': '기본색', 'hasImage': false, 'imageUrl': '', 'buttonCard': true, 'active': true},
    {'id': 'c2', 'name': '화이트', 'hexCode': '#FFFFFF', 'category': '기본색', 'hasImage': false, 'imageUrl': '', 'buttonCard': true, 'active': true},
    {'id': 'c3', 'name': '네이비', 'hexCode': '#1B2A4A', 'category': '기본색', 'hasImage': false, 'imageUrl': '', 'buttonCard': true, 'active': true},
    {'id': 'c4', 'name': '그레이', 'hexCode': '#888888', 'category': '기본색', 'hasImage': false, 'imageUrl': '', 'buttonCard': true, 'active': true},
    {'id': 'c5', 'name': '카키', 'hexCode': '#4A4A2A', 'category': '포인트색', 'hasImage': true, 'imageUrl': '', 'buttonCard': true, 'active': true},
    {'id': 'c6', 'name': '버건디', 'hexCode': '#6B1A2A', 'category': '포인트색', 'hasImage': false, 'imageUrl': '', 'buttonCard': true, 'active': true},
  ];
  final Set<String> _selectedColorIds = {};
  String _colorCategoryFilter = '전체';
  static const _colorCategories = ['전체', '기본색', '포인트색', '시즌색'];

  // ── 디자인 수정 요청 상태
  final List<Map<String, dynamic>> _designRequests = [];
  final Set<String> _selectedDesignRequestIds = {};
  String _designRequestFilter = '전체';
  static const _designRequestStatuses = ['전체', '대기중', '처리중', '완료', '거절'];

  // ── 캐시된 초기 데이터 (빠른 로딩용)
  List<OrderModel>? _cachedOrders;
  List<Map<String, dynamic>>? _cachedMembers;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 13, vsync: this);
    // initialTab이 지정된 경우 해당 탭으로 이동
    if (widget.initialTab > 0 && widget.initialTab < 13) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabCtrl.animateTo(widget.initialTab);
      });
    }
    _loadAdminSettings();
    _prefetchData();
    // 관리자 화면 진입 시 비활성 상품 포함 전체 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().loadAdminProducts();
      }
    });
  }

  /// 앱 시작 시 주요 데이터를 미리 로드해 탭 전환 시 즉시 표시
  Future<void> _prefetchData() async {
    try {
      final orders = await OrderService.getAllOrders();
      if (!mounted) return;
      setState(() => _cachedOrders = orders);
    } catch (_) {}

    try {
      // 회원 데이터 프리페치
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .limit(500)
          .get();
      if (!mounted) return;
      final members = userSnap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['uid'] = d.id;
        return data;
      }).toList();
      setState(() => _cachedMembers = members);
    } catch (_) {}

    // 디자인 수정 요청: Firestore orders에서 colorEditRequested=true인 주문 로드
    await _loadDesignRequests();
  }

  Future<void> _loadDesignRequests() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('colorEditRequested', isEqualTo: true)
          .get();
      if (!mounted) return;
      final requests = snap.docs.map((doc) {
        final d = doc.data();
        final opts = d['customOptions'] as Map<String, dynamic>? ?? {};
        final raw = d['colorEditRequestedAt'];
        DateTime createdAt;
        if (raw is Timestamp) {
          createdAt = raw.toDate();
        } else {
          final fallback = d['createdAt'];
          if (fallback is Timestamp) {
            createdAt = fallback.toDate();
          } else {
            createdAt = DateTime.now();
          }
        }
        final newColor = d['newColorName'] as String? ?? opts['newColorName'] as String? ?? '';
        final newTeamName = d['newTeamName'] as String? ?? '';
        final memo = d['colorEditMemo'] as String? ?? '';
        String desc = '';
        if (newColor.isNotEmpty) desc += '색상: $newColor';
        if (newTeamName.isNotEmpty) desc += (desc.isNotEmpty ? ' / ' : '') + '팀명: $newTeamName';
        if (memo.isNotEmpty) desc += (desc.isNotEmpty ? ' / ' : '') + '메모: $memo';
        return {
          'id': doc.id,
          'orderId': doc.id,
          'userName': d['userName'] as String? ?? '-',
          'requestType': '색상/팀명 변경',
          'description': desc.isNotEmpty ? desc : '변경 요청',
          'status': '대기중',
          'createdAt': createdAt,
          'images': <String>[],
          'adminNote': '',
        };
      }).toList();
      requests.sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      if (!mounted) return;
      setState(() {
        _designRequests.clear();
        _designRequests.addAll(requests);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('디자인 수정 요청 로드 실패: $e');
    }
  }

  Future<void> _loadAdminSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _adminPhone = prefs.getString('admin_phone') ?? '';
      _notifyNewChat = prefs.getBool('notify_chat') ?? true;
      _notifyNewOrder = prefs.getBool('notify_order') ?? true;
      _notifyChatSms = prefs.getBool('notify_sms') ?? false;
    });
  }

  Future<void> _saveAdminSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_phone', _adminPhone);
    await prefs.setBool('notify_chat', _notifyNewChat);
    await prefs.setBool('notify_order', _notifyNewOrder);
    await prefs.setBool('notify_sms', _notifyChatSms);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final width = MediaQuery.of(context).size.width;
    // 태블릿/PC 모두 넓은 화면이면 사이드바 레이아웃 사용
    final isPc = width >= 900;

    if (isPc) {
      return _buildPcLayout(user);
    }
    return _buildMobileLayout(user);
  }

  // ══════════════════════════════════════════════
  // PC 레이아웃: 좌측 사이드바 + 우측 컨텐츠
  // ══════════════════════════════════════════════
  Widget _buildPcLayout(dynamic user) {
    final tabs = [
      {'icon': Icons.dashboard_rounded, 'label': '대시보드'},
      {'icon': Icons.receipt_long_rounded, 'label': '주문관리'},
      {'icon': Icons.inventory_2_rounded, 'label': '상품관리'},
      {'icon': Icons.image_rounded, 'label': '배너관리'},
      {'icon': Icons.people_alt_rounded, 'label': '회원관리'},
      {'icon': Icons.layers_rounded, 'label': '섹션관리'},
      {'icon': Icons.palette_rounded, 'label': '색상관리'},
      {'icon': Icons.design_services_rounded, 'label': '디자인요청'},
      {'icon': Icons.chat_rounded, 'label': '채팅상담'},
      {'icon': Icons.bar_chart_rounded, 'label': '매출통계'},
      {'icon': Icons.warehouse_rounded, 'label': '재고관리'},
      {'icon': Icons.badge_rounded, 'label': '직원관리'},
      {'icon': Icons.campaign_rounded, 'label': '공지관리'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          // ── 좌측 사이드바 (220px) ──
          Container(
            width: 220,
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                // 로고 영역
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('2FIT MALL', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                              Text('관리자 콘솔', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, size: 14, color: AppColors.accent),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user?.name ?? '관리자', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white38, fontSize: 9), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 구분선
                Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                // 탭 메뉴
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: tabs.length,
                    itemBuilder: (ctx, i) {
                      final isSelected = _tabCtrl.index == i;
                      final hasNotif = i == 8 && _pendingChatCount > 0;
                      return GestureDetector(
                        onTap: () => setState(() => _tabCtrl.animateTo(i)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tabs[i]['icon'] as IconData,
                                size: 16,
                                color: isSelected ? AppColors.accent : Colors.white38,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tabs[i]['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.accent : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (hasNotif)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$_pendingChatCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 알림 + 뒤로가기 + 로그아웃
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                  child: Column(
                    children: [
                      // 홈으로 뒤로가기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white70),
                          label: const Text('홈으로 돌아가기', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (r) => false,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                      Expanded(
                        child: StreamBuilder<List<AdminNotification>>(
                          stream: AdminNotificationStore.stream,
                          builder: (ctx, _) {
                            final unread = AdminNotificationStore.unreadCount;
                            return TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                backgroundColor: unread > 0 ? const Color(0xFFFFD600).withValues(alpha: 0.12) : Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined, size: 16, color: unread > 0 ? const Color(0xFFFFD600) : Colors.white38),
                                  if (unread > 0)
                                    Positioned(
                                      right: -4, top: -4,
                                      child: Container(
                                        width: 12, height: 12,
                                        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                                        child: Text('$unread', style: const TextStyle(fontSize: 7, color: Colors.white), textAlign: TextAlign.center),
                                      ),
                                    ),
                                ],
                              ),
                              label: Text(unread > 0 ? '알림 $unread' : '알림', style: TextStyle(fontSize: 11, color: unread > 0 ? const Color(0xFFFFD600) : Colors.white38)),
                              onPressed: () { setState(() {}); _showAdminNotifications(); },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white38),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('로그아웃'),
                              content: const Text('관리자 계정에서 로그아웃하시겠습니까?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('로그아웃', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await AuthService.logout();
                            context.read<UserProvider>().logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                          }
                        },
                        tooltip: '로그아웃',
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── 우측 컨텐츠 ──
          Expanded(
            child: Column(
              children: [
                // 상단 헤더 바
                Container(
                  height: 52,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        tabs[_tabCtrl.index]['label'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                      const Spacer(),
                      Text(
                        _today(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0xFFEEEEEE)),
                // 탭 컨텐츠 - 현재 탭만 렌더링 (AnimatedBuilder 기반)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (_, __) => _buildCurrentTab(_tabCtrl.index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 모바일 레이아웃 (기존 코드)
  // ══════════════════════════════════════════════
  Widget _buildMobileLayout(dynamic user) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2FIT MALL 관리자', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                Text(user?.name ?? '', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.55))),
              ],
            ),
          ],
        ),
        actions: [
          // 알림 아이콘 with 배지
          StreamBuilder<List<AdminNotification>>(
            stream: AdminNotificationStore.stream,
            builder: (ctx, snapshot) {
              final unread = AdminNotificationStore.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                      size: 19,
                      color: unread > 0 ? const Color(0xFFFFD600) : Colors.white,
                    ),
                    onPressed: () { setState(() {}); _showAdminNotifications(); },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 19),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('관리자 계정에서 로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('로그아웃',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await AuthService.logout();
                context.read<UserProvider>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          tabs: [
            const Tab(icon: Icon(Icons.dashboard_rounded, size: 14), text: '대시보드'),
            const Tab(icon: Icon(Icons.receipt_long_rounded, size: 14), text: '주문관리'),
            const Tab(icon: Icon(Icons.inventory_2_rounded, size: 14), text: '상품관리'),
            const Tab(icon: Icon(Icons.image_rounded, size: 14), text: '배너관리'),
            const Tab(icon: Icon(Icons.people_alt_rounded, size: 14), text: '회원관리'),
            const Tab(icon: Icon(Icons.layers_rounded, size: 14), text: '섹션관리'),
            const Tab(icon: Icon(Icons.palette_rounded, size: 14), text: '색상관리'),
            const Tab(icon: Icon(Icons.design_services_rounded, size: 14), text: '디자인요청'),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_rounded, size: 14),
                  if (_pendingChatCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_pendingChatCount',
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              text: '채팅상담',
            ),
            const Tab(icon: Icon(Icons.bar_chart_rounded, size: 14), text: '매출통계'),
            const Tab(icon: Icon(Icons.warehouse_rounded, size: 14), text: '재고관리'),
            const Tab(icon: Icon(Icons.badge_rounded, size: 14), text: '직원관리'),
            const Tab(icon: Icon(Icons.campaign_rounded, size: 14), text: '공지관리'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => _buildCurrentTab(_tabCtrl.index),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 현재 탭 인덱스에 맞는 위젯만 빌드 (핵심 렌더링 메서드)
  // ══════════════════════════════════════════════
  Widget _buildCurrentTab(int index) {
    // Stack+Offstage: 모든 탭을 미리 빌드해두고 보이기/숨기기만 전환
    // → 탭 전환 시 재빌드 없음, 스트림 구독 유지
    return Stack(
      children: [
        Offstage(offstage: index != 0, child: _buildDashboard()),
        Offstage(offstage: index != 1, child: _buildOrderManagement()),
        Offstage(offstage: index != 2, child: _buildProductManagement()),
        Offstage(offstage: index != 3, child: _buildBannerManagement()),
        Offstage(offstage: index != 4, child: _buildMemberManagement()),
        Offstage(offstage: index != 5, child: _buildSectionManagement()),
        Offstage(offstage: index != 6, child: _buildColorManagement()),
        Offstage(offstage: index != 7, child: _buildDesignRequests()),
        Offstage(offstage: index != 8, child: _buildChatManagement()),
        Offstage(offstage: index != 9, child: const AdminSalesStatsTab()),
        Offstage(offstage: index != 10, child: const AdminInventoryTab()),
        Offstage(offstage: index != 11, child: const AdminStaffTab()),
        Offstage(offstage: index != 12, child: _buildNoticeManagement()),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // TAB 13 : 공지사항 관리
  // ══════════════════════════════════════════════
  Widget _buildNoticeManagement() => const _NoticeManagementTab();

  // ══════════════════════════════════════════════
  // TAB 1 : 대시보드
  // ══════════════════════════════════════════════
  Widget _buildDashboard() {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      initialData: _cachedOrders,
      builder: (context, snapshot) {
        final allOrders = snapshot.data ?? [];
        final now = DateTime.now();
        final todayOrders = allOrders.where((o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day).toList();
        final monthOrders = allOrders.where((o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month).toList();
        final inProgress = allOrders.where((o) =>
          o.status == OrderStatus.processing ||
          o.status == OrderStatus.confirmed).length;
        final deliveredToday = allOrders.where((o) =>
          o.status == OrderStatus.delivered &&
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day).length;
        final monthRevenue = monthOrders.fold<double>(0, (s, o) => s + o.totalAmount);
        final personalOrders = allOrders.where((o) => o.orderType == 'personal').length;
        final groupOrders = allOrders.where((o) => o.orderType == 'group' || o.orderType == 'additional').length;

        return Container(
          color: const Color(0xFFF0F2F5),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 날짜 & 상태 ──
                Row(
                  children: [
                    Text(
                      _today(),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    _chip('실시간', const Color(0xFF43A047)),
                  ],
                ),
                const SizedBox(height: 12),

                // ── KPI 카드 2x2 그리드 ──
                Row(
                  children: [
                    Expanded(child: _kpiCard('오늘 주문', '${todayOrders.length}', Icons.receipt_long_rounded, const Color(0xFF1565C0), '+${todayOrders.length}')),
                    const SizedBox(width: 8),
                    Expanded(child: _kpiCard('이번달 매출', _fmtMillions(monthRevenue), Icons.attach_money_rounded, const Color(0xFF2E7D32), '${monthOrders.length}건')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _kpiCard('제작 진행', '$inProgress', Icons.precision_manufacturing_rounded, const Color(0xFF6A1B9A), '처리중')),
                    const SizedBox(width: 8),
                    Expanded(child: _kpiCard('배송 완료', '$deliveredToday', Icons.local_shipping_rounded, const Color(0xFF00838F), '오늘')),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 매출 현황 ──
                _sectionTitle('매출 현황', Icons.bar_chart_rounded),
                const SizedBox(height: 8),
                _buildSalesStats(allOrders),
                const SizedBox(height: 16),

                // ── 주문 유형 ──
                _sectionTitle('주문 유형', Icons.pie_chart_rounded),
                const SizedBox(height: 8),
                Container(
                  decoration: _cardDeco(),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(
                    children: [
                      _orderTypeRow('개인 주문', personalOrders, const Color(0xFF1565C0)),
                      const SizedBox(height: 10),
                      _orderTypeRow('단체/추가제작', groupOrders, const Color(0xFF6A1B9A)),
                      const SizedBox(height: 10),
                      _orderTypeRow('총 주문', allOrders.length, const Color(0xFF00838F)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 최근 주문 ──
                _sectionTitle('최근 주문', Icons.history_rounded),
                const SizedBox(height: 8),
                ...allOrders.take(5).map(_recentOrderRow),
                if (allOrders.isEmpty)
                  Container(
                    decoration: _cardDeco(),
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Text('아직 주문이 없습니다', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                    ),
                  ),
                const SizedBox(height: 16),

                // ── 빠른 작업 ──
                _sectionTitle('빠른 작업', Icons.flash_on_rounded),
                const SizedBox(height: 8),
                Container(
                  decoration: _cardDeco(),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _quickActionRow(Icons.add_box_rounded, '상품 추가', const Color(0xFF1565C0), () => _tabCtrl.animateTo(2)),
                      const SizedBox(height: 6),
                      _quickActionRow(Icons.image_rounded, '배너 추가', const Color(0xFF2E7D32), () => _tabCtrl.animateTo(3)),
                      const SizedBox(height: 6),
                      _quickActionRow(Icons.chat_rounded, '고객 채팅', const Color(0xFF6A1B9A), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                      }),
                      const SizedBox(height: 6),
                      _quickActionRow(Icons.download_rounded, '주문 내보내기', const Color(0xFFE53935), () {
                        _exportOrdersCSV(allOrders);
                      }),
                      const SizedBox(height: 6),
                      _quickActionRow(Icons.table_chart_rounded, '단체 일일엑셀 (오후1시 마감)', const Color(0xFF00897B), () {
                        _exportDailyExcel();
                      }),
                      const SizedBox(height: 6),
                      _quickActionRow(Icons.notifications_active_rounded, '전체 알림 발송', const Color(0xFFFF6F00), () {
                        _showPromoNotificationDialog();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtMillions(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '${amount.toInt()}';
  }

  Widget _buildSalesStats(List<OrderModel> allOrders) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    double calcRevenue(DateTime from, DateTime to) =>
      allOrders.where((o) => o.createdAt.isAfter(from.subtract(const Duration(seconds: 1))) &&
          o.createdAt.isBefore(to.add(const Duration(days: 1)))).fold(0.0, (s, o) => s + o.totalAmount);

    final todayRev = calcRevenue(todayStart, now);
    final weekRev = calcRevenue(weekStart, now);
    final monthRev = calcRevenue(monthStart, now);
    final lastMonthRev = calcRevenue(lastMonthStart, lastMonthEnd);

    return Container(
      decoration: _cardDeco(),
      child: Column(
        children: [
          _salesRow('오늘', '${_fmtPrice(todayRev)}원', allOrders.where((o) => o.createdAt.isAfter(todayStart)).length.toString(), true),
          _divider(),
          _salesRow('이번 주', '${_fmtPrice(weekRev)}원', allOrders.where((o) => o.createdAt.isAfter(weekStart)).length.toString(), true),
          _divider(),
          _salesRow('이번 달', '${_fmtPrice(monthRev)}원', allOrders.where((o) => o.createdAt.isAfter(monthStart)).length.toString(), true),
          _divider(),
          _salesRow('지난 달', '${_fmtPrice(lastMonthRev)}원', allOrders.where((o) => o.createdAt.isAfter(lastMonthStart) && o.createdAt.isBefore(monthStart)).length.toString(), false),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 2 : 주문 관리
  // ══════════════════════════════════════════════
  Widget _buildOrderManagement() {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      initialData: _cachedOrders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE53935)),
                const SizedBox(height: 12),
                Text('데이터 로드 실패: ${snapshot.error}', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text('다시 시도')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return Container(
            color: const Color(0xFFF4F6FA),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E))),
          );
        }
        final allOrders = snapshot.data ?? [];
        // 검색 + 상태 필터 적용
        var filtered = _orderFilterIdx == 0
            ? allOrders
            : allOrders.where((o) => o.status.label == _orderFilters[_orderFilterIdx]).toList();
        if (_orderSearchQuery.isNotEmpty) {
          final q = _orderSearchQuery.toLowerCase();
          filtered = filtered.where((o) =>
            o.id.toLowerCase().contains(q) ||
            o.userName.toLowerCase().contains(q)
          ).toList();
        }
        final allSelected = filtered.isNotEmpty &&
            filtered.every((o) => _selectedOrderIds.contains(o.id));
        final anySelected = _selectedOrderIds.isNotEmpty;

        return Column(
          children: [
            // ── 검색바 ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      onChanged: (v) => setState(() {
                        _orderSearchQuery = v;
                        _selectedOrderIds.clear();
                      }),
                      decoration: InputDecoration(
                        hintText: '주문번호 / 고객명 검색...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 예시 엑셀 다운로드 버튼
                  Tooltip(
                    message: '예시 엑셀 파일 다운로드 (샘플 데이터)',
                    child: InkWell(
                      onTap: _downloadSampleExcel,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57F17).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF57F17).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_download_outlined, size: 15, color: Color(0xFFF57F17)),
                            SizedBox(width: 4),
                            Text('예시파일', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF57F17))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 일일 마감 엑셀 버튼
                  Tooltip(
                    message: '단체 일일엑셀 (전날 13:00 ~ 오늘 13:00, 단체주문만)',
                    child: InkWell(
                      onTap: _exportDailyExcel,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.table_chart_rounded, size: 15, color: Color(0xFF00897B)),
                            SizedBox(width: 4),
                            Text('단체일일엑셀', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00897B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _iconBtn(Icons.download_rounded, () {
                    _exportOrdersCSV(filtered);
                  }),
                  const SizedBox(width: 6),
                  // 주문 상태 자동 업데이트 버튼
                  Tooltip(
                    message: '주문 상태 자동 업데이트',
                    child: InkWell(
                      onTap: () => _showAutoUpdateOrdersDialog(allOrders),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.autorenew_rounded, size: 18, color: Color(0xFF1565C0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _iconBtn(Icons.filter_list_rounded, () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('주문 정렬', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                          ..._orderFilters.skip(1).map((s) => ListTile(
                            title: Text(s),
                            trailing: _orderFilters[_orderFilterIdx] == s
                                ? const Icon(Icons.check, color: Color(0xFF1A1A2E))
                                : null,
                            onTap: () {
                              setState(() => _orderFilterIdx = _orderFilters.indexOf(s));
                              Navigator.pop(context);
                            },
                          )),
                          ListTile(
                            title: const Text('전체 보기'),
                            onTap: () {
                              setState(() => _orderFilterIdx = 0);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // ── 상태 필터 칩 ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _orderFilters.asMap().entries.map((e) {
                    final sel = _orderFilterIdx == e.key;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _orderFilterIdx = e.key;
                        _selectedOrderIds.clear();
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF1A1A2E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD)),
                        ),
                        child: Text(e.value, style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? Colors.white : const Color(0xFF555555),
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // ── 전체선택 + 일괄액션 툴바 ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: anySelected ? const Color(0xFFEEF2FF) : const Color(0xFFF4F6FA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  // 전체선택 체크박스
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          _selectedOrderIds.removeAll(filtered.map((o) => o.id));
                        } else {
                          _selectedOrderIds.addAll(filtered.map((o) => o.id));
                        }
                      });
                    },
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            allSelected
                                ? Icons.check_box_rounded
                                : _selectedOrderIds.isEmpty
                                    ? Icons.check_box_outline_blank_rounded
                                    : Icons.indeterminate_check_box_rounded,
                            key: ValueKey(allSelected ? 'all' : _selectedOrderIds.isEmpty ? 'none' : 'partial'),
                            color: allSelected || !_selectedOrderIds.isEmpty
                                ? const Color(0xFF3949AB)
                                : const Color(0xFF888888),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          anySelected ? '전체선택' : '전체선택',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: anySelected ? const Color(0xFF3949AB) : const Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 선택 카운트 배지
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: anySelected
                        ? Container(
                            key: const ValueKey('badge'),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3949AB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_selectedOrderIds.length}건 선택',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          )
                        : Text(
                            '총 ${filtered.length}건',
                            key: const ValueKey('total'),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                          ),
                  ),
                  const Spacer(),
                  // 선택 시 액션 버튼들
                  if (anySelected) ...[
                    // 선택 엑셀 다운로드
                    GestureDetector(
                      onTap: () => _exportSelectedOrdersExcel(
                        filtered.where((o) => _selectedOrderIds.contains(o.id)).toList(),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.table_chart_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('엑셀', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    // 일괄 상태변경
                    GestureDetector(
                      onTap: () => _showBulkStatusChangeDialog(filtered),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3949AB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.sync_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('상태', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    // 선택 삭제
                    GestureDetector(
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(children: [
                              Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 22),
                              SizedBox(width: 8),
                              Text('주문 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
                            ]),
                            content: Text('선택한 ${_selectedOrderIds.length}건의 주문을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && mounted) {
                          for (final id in _selectedOrderIds.toList()) {
                            await OrderService.deleteOrder(id);
                          }
                          setState(() => _selectedOrderIds.clear());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('선택한 주문이 삭제되었습니다'), backgroundColor: Color(0xFF1A1A2E)),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('삭제', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ],
                  // 선택 없을 때 힌트
                  if (!anySelected)
                    const Text(
                      '카드를 눌러 상세보기  ·  □ 체크로 선택',
                      style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 12),
                          Text('주문 내역이 없습니다', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _orderCard(filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // CSV 내보내기
  // ── 선택 주문 엑셀 내보내기 ──
  Future<void> _exportSelectedOrdersExcel(List<OrderModel> selectedOrders) async {
    if (selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택된 주문이 없습니다.'), backgroundColor: Color(0xFF555555)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1A1A2E)),
                SizedBox(height: 16),
                Text('엑셀 파일 생성 중...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final now = DateTime.now();
      final bytes = await OrderExcelService.generateSelectedOrdersExcel(selectedOrders, now);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final dateStr = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}';
      final fileName = '2FIT_선택주문_${selectedOrders.length}건_$dateStr.xlsx';
      await _handleExcelDownload(bytes, fileName, selectedOrders.length, now, now);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('엑셀 생성 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _exportOrdersCSV(List<OrderModel> orders) {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내보낼 주문이 없습니다.'), backgroundColor: Color(0xFF1A1A2E)),
      );
      return;
    }
    // 날짜별 내보내기 선택 다이얼로그
    _showExportDialog(orders);
  }

  // ──────────────────────────────────────────────
  // 일일 엑셀 내보내기 (전날 오후 1시 ~ 당일 오후 1시)
  // ──────────────────────────────────────────────
  // ── 예시(샘플) 엑셀 파일 다운로드 ──
  Future<void> _downloadSampleExcel() async {
    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    const fileName = '2FIT_주문엑셀_예시파일.xlsx';
    try {
      final bytes = OrderExcelService.generateSampleExcel();
      if (kIsWeb) {
        downloadFileWeb(bytes, fileName, mimeType);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.file_download_done_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('예시 엑셀 파일 다운로드 완료 (PC에서 바로 열기 가능)')),
            ]),
            backgroundColor: const Color(0xFFF57F17),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // 모바일: 바로 공유 시트 열기
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        await Share.shareXFiles(
          [XFile(filePath, mimeType: mimeType, name: fileName)],
          subject: '2FIT MALL 엑셀 예시 파일',
          text: fileName,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예시 파일 생성 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportDailyExcel() async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1A1A2E)),
                SizedBox(height: 16),
                Text('주문 데이터 조회 중...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final range = OrderExcelService.getDailyRange();
      final orders = await OrderExcelService.getOrdersByDateRange(
          range.start, range.end);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 닫기

      // ── 단체주문만 필터 (기성품/개인 주문 제외) ──
      final groupOnlyOrders = orders.where((o) {
        if (o.orderType == 'group' || o.orderType == 'additional') return true;
        final isGrpId = o.id.startsWith('GRP_') || o.id.startsWith('GROUP-');
        final hasTeamName = (o.customOptions?['teamName'] as String?)?.isNotEmpty == true;
        final hasPersons = (o.customOptions?['persons'] as List?)?.isNotEmpty == true;
        return isGrpId || (hasTeamName && hasPersons);
      }).toList();

      if (groupOnlyOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_fmtDateKr(range.start)} ~ ${_fmtDateKr(range.end)} 기간에 단체주문이 없습니다.',
            ),
            backgroundColor: const Color(0xFF555555),
          ),
        );
        return;
      }

      // 엑셀 생성 (단체주문 전용 — 이미지 URL 포함)
      final bytes = await OrderExcelService.generateDailyGroupOrderExcel(groupOnlyOrders, range.start, range.end);
      final startStr = '${range.start.month.toString().padLeft(2, '0')}${range.start.day.toString().padLeft(2, '0')}';
      final endStr = '${range.end.month.toString().padLeft(2, '0')}${range.end.day.toString().padLeft(2, '0')}';
      final fileName = '2FIT_단체일일엑셀_${startStr}_${endStr}.xlsx';

      await _handleExcelDownload(bytes, fileName, groupOnlyOrders.length, range.start, range.end);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 날짜 한국어 포맷
  String _fmtDateKr(DateTime dt) =>
      '${dt.month}월 ${dt.day}일 ${dt.hour.toString().padLeft(2, '0')}:00';

  // ── Android Downloads 폴더에 직접 저장 ──
  // 엑셀 공유/저장 처리 (Android 11+ 보안정책 대응)
  // - 웹(PC/태블릿 브라우저): anchor 다운로드 → 브라우저 다운로드 폴더
  // - Android: 임시폴더 저장 후 공유 시트 → 사용자가 "내 파일에 저장" 선택
  Future<void> _handleExcelDownload(
      Uint8List bytes, String fileName, int orderCount,
      DateTime start, DateTime end) async {
    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    if (kIsWeb) {
      // ── 웹(PC/태블릿) : 브라우저 자동 다운로드 ──
      downloadFileWeb(bytes, fileName, mimeType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$orderCount건 엑셀 다운로드 완료!',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Text('📂 화면 하단 다운로드 바 또는 내 PC → 다운로드 폴더 확인',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ]),
          backgroundColor: const Color(0xFF00897B),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      // ── Android 앱 : 바로 공유 시트 열기 ──
      try {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        // 바로 공유 시트 열기 (다이얼로그 없이)
        await Share.shareXFiles(
          [XFile(filePath, mimeType: mimeType, name: fileName)],
          subject: '2FIT 주문내역 $orderCount건',
          text: fileName,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 저장 방법 안내 행
  Widget _saveGuideRow(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF00897B)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ]),
      ]),
    );
  }

  // ──────────────────────────────────────────────
  // 주문 상태 자동 업데이트 다이얼로그
  // ──────────────────────────────────────────────
  void _showAutoUpdateOrdersDialog(List<OrderModel> orders) {
    // 자동 업데이트 가능한 주문 파악
    final now = DateTime.now();
    // 1) 주문확인(confirmed) → 3일 이상 → 제작중(processing)
    final toProcessing = orders.where((o) =>
      o.status == OrderStatus.confirmed &&
      now.difference(o.createdAt).inDays >= 3
    ).toList();

    // 2) 제작중(processing) → 7일 이상 → 배송중(shipped)
    final toShipped = orders.where((o) =>
      o.status == OrderStatus.processing &&
      now.difference(o.createdAt).inDays >= 7
    ).toList();

    // 3) 배송중(shipped) → 3일 이상 → 배송완료(delivered)
    final toDelivered = orders.where((o) =>
      o.status == OrderStatus.shipped &&
      now.difference(o.createdAt).inDays >= 3
    ).toList();

    final totalCount = toProcessing.length + toShipped.length + toDelivered.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.autorenew_rounded, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('주문 상태 자동 업데이트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '자동 업데이트 가능: $totalCount건',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                '경과 기간 기준으로 다음 단계로 자동 진행됩니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (toProcessing.isNotEmpty) _autoUpdateSection(
                icon: Icons.precision_manufacturing_rounded,
                color: Colors.purple,
                label: '주문확인 → 제작중 (3일 이상)',
                count: toProcessing.length,
              ),
              if (toShipped.isNotEmpty) _autoUpdateSection(
                icon: Icons.local_shipping_rounded,
                color: Colors.teal,
                label: '제작중 → 배송중 (7일 이상)',
                count: toShipped.length,
              ),
              if (toDelivered.isNotEmpty) _autoUpdateSection(
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                label: '배송중 → 배송완료 (3일 이상)',
                count: toDelivered.length,
              ),
              if (totalCount == 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(child: Text('모든 주문이 최신 상태입니다!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          if (totalCount > 0)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _executeAutoUpdate(toProcessing, toShipped, toDelivered);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('$totalCount건 자동 업데이트'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _autoUpdateSection({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text('$count건', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAutoUpdate(
    List<OrderModel> toProcessing,
    List<OrderModel> toShipped,
    List<OrderModel> toDelivered,
  ) async {
    int updated = 0;
    int failed = 0;
    final batch = FirebaseFirestore.instance.batch();

    try {
      for (final o in toProcessing) {
        batch.update(
          FirebaseFirestore.instance.collection('orders').doc(o.id),
          {'status': 'processing', 'updatedAt': FieldValue.serverTimestamp()},
        );
        updated++;
      }
      for (final o in toShipped) {
        batch.update(
          FirebaseFirestore.instance.collection('orders').doc(o.id),
          {'status': 'shipped', 'updatedAt': FieldValue.serverTimestamp()},
        );
        updated++;
      }
      for (final o in toDelivered) {
        batch.update(
          FirebaseFirestore.instance.collection('orders').doc(o.id),
          {'status': 'delivered', 'updatedAt': FieldValue.serverTimestamp()},
        );
        updated++;
      }
      await batch.commit();

      // 알림 발송
      for (final o in [...toProcessing, ...toShipped, ...toDelivered]) {
        final newStatus = toProcessing.contains(o) ? OrderStatus.processing
            : toShipped.contains(o) ? OrderStatus.shipped
            : OrderStatus.delivered;
        await FcmService.sendOrderStatusNotification(
          order: o,
          newStatus: newStatus,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $updated건 자동 업데이트 완료' + (failed > 0 ? ' ($failed건 실패)' : '')),
            backgroundColor: const Color(0xFF1565C0),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업데이트 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportDialog(List<OrderModel> allOrders) {
    String exportType = '일일'; // '일일'=전날오후1시~당일오후1시, '전체', '날짜선택'
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          // ── 기간 범위 계산 (UI 미리보기용 - 로컬 필터)
          DateTime? filterStart;
          DateTime? filterEnd;

          if (exportType == '일일') {
            final range = OrderExcelService.getDailyRange();
            filterStart = range.start;
            filterEnd = range.end;
          } else if (exportType == '날짜선택') {
            filterStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 0);
            filterEnd = filterStart.add(const Duration(days: 1));
          }

          // 로컬 미리보기 카운트 (Firestore에서 실제 조회는 다운로드 시 진행)
          int previewCount;
          if (exportType == '전체') {
            previewCount = allOrders.length;
          } else if (filterStart != null && filterEnd != null) {
            final fS = filterStart;
            final fE = filterEnd;
            previewCount = allOrders.where((o) =>
                !o.createdAt.isBefore(fS) && o.createdAt.isBefore(fE)).length;
          } else {
            previewCount = 0;
          }

          String rangeLabel = '';
          if (exportType == '일일' && filterStart != null && filterEnd != null) {
            rangeLabel = '${_fmtDateKr(filterStart)} ~ ${_fmtDateKr(filterEnd)}';
          } else if (exportType == '날짜선택' && filterStart != null && filterEnd != null) {
            rangeLabel = '${_fmtDateKr(filterStart)} ~ ${_fmtDateKr(filterEnd)}';
          } else if (exportType == '전체') {
            rangeLabel = '전체 기간';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('주문 내역 엑셀 내보내기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('내보내기 기간', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  // 3가지 옵션
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setD(() => exportType = '일일'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: exportType == '일일' ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                              border: exportType == '일일'
                                  ? null
                                  : Border.all(color: const Color(0xFFDDDDDD)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.today_rounded, size: 18,
                                    color: exportType == '일일' ? Colors.white : const Color(0xFF555555)),
                                const SizedBox(height: 2),
                                Text('일일 마감',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                        color: exportType == '일일' ? Colors.white : const Color(0xFF555555))),
                                Text('전날1시~오늘1시',
                                    style: TextStyle(fontSize: 9,
                                        color: exportType == '일일' ? Colors.white70 : const Color(0xFF999999))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setD(() => exportType = '날짜선택'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: exportType == '날짜선택' ? const Color(0xFF1565C0) : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                              border: exportType == '날짜선택'
                                  ? null
                                  : Border.all(color: const Color(0xFFDDDDDD)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.date_range_rounded, size: 18,
                                    color: exportType == '날짜선택' ? Colors.white : const Color(0xFF555555)),
                                const SizedBox(height: 2),
                                Text('날짜 선택',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                        color: exportType == '날짜선택' ? Colors.white : const Color(0xFF555555))),
                                Text('특정일 지정',
                                    style: TextStyle(fontSize: 9,
                                        color: exportType == '날짜선택' ? Colors.white70 : const Color(0xFF999999))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setD(() => exportType = '전체'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: exportType == '전체' ? const Color(0xFF2E7D32) : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                              border: exportType == '전체'
                                  ? null
                                  : Border.all(color: const Color(0xFFDDDDDD)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.all_inbox_rounded, size: 18,
                                    color: exportType == '전체' ? Colors.white : const Color(0xFF555555)),
                                const SizedBox(height: 2),
                                Text('전체',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                        color: exportType == '전체' ? Colors.white : const Color(0xFF555555))),
                                Text('전체 주문',
                                    style: TextStyle(fontSize: 9,
                                        color: exportType == '전체' ? Colors.white70 : const Color(0xFF999999))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (exportType == '날짜선택') ...[
                    const SizedBox(height: 12),
                    const Text('날짜 선택 (해당일 13:00 ~ 익일 13:00)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF1A1A2E)),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setD(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1565C0)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFE3F2FD),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF1565C0)),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1565C0)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 기간 표시 + 건수
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCCD6FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rangeLabel.isNotEmpty) ...[
                          Row(children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF1A1A2E)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(rangeLabel,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
                          ]),
                          const SizedBox(height: 4),
                        ],
                        Row(children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF888888)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(
                            previewCount > 0
                                ? '$previewCount건 확인됨 · 3개 시트(주문요약/배송목록/상품집계) 엑셀 파일'
                                : '로딩된 주문 범위 외 · 다운로드 시 Firestore 재조회',
                            style: TextStyle(
                              fontSize: 11,
                              color: previewCount > 0
                                  ? const Color(0xFF555555)
                                  : const Color(0xFF1565C0),
                              fontWeight: previewCount == 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          )),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.table_chart_rounded, size: 16),
                label: const Text('엑셀 다운로드', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  // 실제 날짜 범위로 Firestore에서 재조회 후 엑셀 생성
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF1A1A2E)),
                              SizedBox(height: 16),
                              Text('엑셀 파일 생성 중...', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  try {
                    List<OrderModel> finalOrders;
                    DateTime fStart;
                    DateTime fEnd;

                    if (exportType == '일일') {
                      final range = OrderExcelService.getDailyRange();
                      fStart = range.start;
                      fEnd = range.end;
                      finalOrders = await OrderExcelService.getOrdersByDateRange(fStart, fEnd);
                    } else if (exportType == '날짜선택') {
                      fStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 0);
                      fEnd = fStart.add(const Duration(days: 1));
                      finalOrders = await OrderExcelService.getOrdersByDateRange(fStart, fEnd);
                    } else {
                      // 전체 주문: Firestore 전체 재조회
                      fStart = DateTime(2020);
                      fEnd = DateTime.now().add(const Duration(days: 1));
                      finalOrders = await OrderExcelService.getOrdersByDateRange(fStart, fEnd);
                    }

                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();

                    if (finalOrders.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('해당 기간에 주문이 없습니다.'), backgroundColor: Color(0xFF555555)),
                      );
                      return;
                    }

                    final bytes = await OrderExcelService.generateExcel(finalOrders, fStart, fEnd);
                    final startStr = '${fStart.month.toString().padLeft(2, '0')}${fStart.day.toString().padLeft(2, '0')}';
                    final endStr = '${fEnd.month.toString().padLeft(2, '0')}${fEnd.day.toString().padLeft(2, '0')}';
                    final fileName = '2FIT_주문_${startStr}_${endStr}.xlsx';
                    await _handleExcelDownload(bytes, fileName, finalOrders.length, fStart, fEnd);
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('엑셀 생성 오류: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _doExportCSV(List<OrderModel> orders, String fileName) {
    final sb = StringBuffer();
    // BOM for Excel UTF-8
    sb.write('\uFEFF');
    sb.writeln('주문번호,주문자,연락처,배송지,주문유형,상품,수량,총금액,결제방법,상태,주문일시');
    for (final o in orders) {
      final items = o.items.map((i) => '${i.productName}(${i.size}/${i.color})').join(' | ');
      final qty = o.items.fold<int>(0, (sum, i) => sum + i.quantity);
      final date = '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')} ${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}';
      sb.writeln([
        o.id, o.userName, o.userPhone,
        '"${o.userAddress.replaceAll('"', '""')}"',
        o.orderType, '"$items"', qty,
        o.totalAmount.toInt(), o.paymentMethod,
        o.status.label, date,
      ].join(','));
    }
    if (kIsWeb) {
      final csvBytes = Uint8List.fromList(sb.toString().codeUnits);
      downloadFileWeb(csvBytes, fileName, 'text/csv;charset=utf-8');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('${orders.length}건 다운로드: $fileName'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV 내보내기는 웹 환경에서만 지원됩니다.'), backgroundColor: Color(0xFF1A1A2E)),
      );
    }
  }

  // 주문 일괄 상태변경 다이얼로그
  void _showBulkStatusChangeDialog(List<OrderModel> filteredOrders) {
    String? selectedStatus;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.sync_rounded, color: Color(0xFF3949AB), size: 22),
            SizedBox(width: 8),
            Text('일괄 상태 변경', style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('선택된 ${_selectedOrderIds.length}건의 주문 상태를 변경합니다.'),
              const SizedBox(height: 16),
              ..._orderFilters.skip(1).map((s) => RadioListTile<String>(
                value: s,
                groupValue: selectedStatus,
                onChanged: (v) => setD(() => selectedStatus = v),
                title: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                dense: true,
                activeColor: const Color(0xFF1A1A2E),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: selectedStatus == null ? null : () {
                Navigator.pop(ctx);
                setState(() => _selectedOrderIds.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_selectedOrderIds.length}건 → "$selectedStatus" 상태 변경 완료'), backgroundColor: const Color(0xFF1A1A2E)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    final statusColor = _statusColor(order.status);
    final isSelected = _selectedOrderIds.contains(order.id);
    // orderType 판별: GRP_/GROUP- ID이거나, persons+teamName 모두 있으면 단체주문
    bool isGroup = order.orderType == 'group' || order.orderType == 'additional';
    if (!isGroup) {
      final isGrpId = order.id.startsWith('GRP_') || order.id.startsWith('GROUP-');
      final hasTeamName = (order.customOptions?['teamName'] as String?)?.isNotEmpty == true;
      final hasPersons = (order.customOptions?['persons'] as List?)?.isNotEmpty == true;
      if (isGrpId || (hasTeamName && hasPersons)) isGroup = true;
    }
    final opts = order.customOptions;

    return GestureDetector(
      // 카드 탭 → 주문 상세 보기
      onTap: () => _showOrderDetailDialog(order),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8EAF6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF3949AB) : isGroup ? const Color(0xFF6A1B9A).withValues(alpha: 0.3) : const Color(0xFFEEEEEE),
          width: isSelected ? 1.5 : isGroup ? 1.5 : 1,
        ),
        boxShadow: isSelected ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8EAF6) : isGroup ? const Color(0xFFF3E5F5) : const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              children: [
                // 체크박스 — 탭 시 선택/해제 (카드 탭과 독립)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedOrderIds.remove(order.id);
                    } else {
                      _selectedOrderIds.add(order.id);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6, left: 4),
                    child: Icon(
                      isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? const Color(0xFF3949AB) : const Color(0xFFBBBBBB),
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(order.id,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _miniTag(
                    order.orderType == 'additional' ? '추가제작' : (isGroup ? '단체' : '개인'),
                    order.orderType == 'additional' ? const Color(0xFFC62828) : (isGroup ? const Color(0xFF6A1B9A) : const Color(0xFF1565C0))),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(order.status.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              order.userName.isNotEmpty
                                  ? order.userName
                                  : (opts?['managerName']?.toString() ?? opts?['manager']?.toString() ?? '주문자 없음'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.userPhone.isNotEmpty ? order.userPhone : '-',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.items.isNotEmpty
                            ? '${order.items.map((i) => i.productName).join(', ')} (${order.items.length}종)'
                            : (opts?['teamName']?.toString() ?? opts?['productName']?.toString() ?? '상품 정보 없음'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // 단체주문 요약 정보
                if (isGroup && opts != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (opts['teamName'] != null && (opts['teamName'] as String).isNotEmpty)
                        _miniTag('팀명: ${opts['teamName']}', const Color(0xFF6A1B9A)),
                      if (opts['totalCount'] != null)
                        _miniTag('${opts['totalCount']}명', const Color(0xFF1565C0)),
                      if (opts['printTypeLabel'] != null)
                        _miniTag(opts['printTypeLabel'] as String, const Color(0xFF2E7D32)),
                      if (opts['mainColor'] != null && (opts['mainColor'] as String).isNotEmpty)
                        _miniTag('색상: ${opts['mainColor']}', const Color(0xFFE65100)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 상태 변경 드롭다운
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: order.status.label,
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                          items: OrderStatus.values
                              .map((s) => DropdownMenuItem(value: s.label, child: Text(s.label)))
                              .toList(),
                          onChanged: (newLabel) async {
                            if (newLabel == null) return;
                            final newStatus = OrderStatus.values.firstWhere(
                              (s) => s.label == newLabel,
                              orElse: () => order.status,
                            );
                            // 배송중 상태로 변경 시 운송장 입력 다이얼로그
                            if (newStatus == OrderStatus.shipped && mounted) {
                              await _showShippingDialog(order.id, newStatus);
                            } else {
                              await OrderService.updateOrderStatus(order.id, newStatus);
                              // FCM 푸시 알림 전송
                              FcmService.sendOrderStatusNotification(
                                order: order,
                                newStatus: newStatus,
                              ).catchError((e) {
                                if (kDebugMode) debugPrint('⚠️ FCM 알림 실패: $e');
                              });
                              if (mounted) {
                                context.read<OrderProvider>().updateOrderStatus(order.id, newStatus);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('주문 ${order.id} 상태: ${newStatus.label} 🔔알림 전송'),
                                    backgroundColor: const Color(0xFF1A1A2E),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 단체주문 상세보기 버튼
                    if (isGroup)
                      GestureDetector(
                        onTap: () => _showGroupOrderDetail(order),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_rounded, size: 14, color: Color(0xFF6A1B9A)),
                              SizedBox(width: 4),
                              Text('팀원 명단', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A))),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${_fmtPrice(order.totalAmount)}원',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        Text(_fmtDate(order.createdAt),
                            style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),   // AnimatedContainer
    );
  }

  // ── 주문 상세 보기 다이얼로그 (모든 주문 공통) ──
  void _showOrderDetailDialog(OrderModel order) {
    // orderType 판별: GRP_/GROUP- ID이거나, persons+teamName 모두 있으면 단체주문
    bool isGroup = order.orderType == 'group' || order.orderType == 'additional';
    if (!isGroup) {
      final isGrpId = order.id.startsWith('GRP_') || order.id.startsWith('GROUP-');
      final hasTeamName = (order.customOptions?['teamName'] as String?)?.isNotEmpty == true;
      final hasPersons = (order.customOptions?['persons'] as List?)?.isNotEmpty == true;
      if (isGrpId || (hasTeamName && hasPersons)) isGroup = true;
    }
    if (isGroup) {
      _showGroupOrderDetail(order);
    } else {
      _showPersonalOrderDetail(order);
    }
  }

  // ── 개인 주문 상세 보기 ──
  void _showPersonalOrderDetail(OrderModel order) {
    OrderModel currentOrder = order;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final statusColor = _statusColor(currentOrder.status);
          return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1A1A2E), const Color(0xFF2D2D5E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.id,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(_fmtDate(order.createdAt),
                              style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(order.status.label,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 주문자 정보 (관리자: 전체 정보 표시)
                      _detailSection('주문자 정보', [
                        _detailRow(Icons.person_outline, '이름', order.userName),
                        _detailRow(Icons.phone_outlined, '연락처', order.userPhone.isNotEmpty ? order.userPhone : '-'),
                        _detailRow(Icons.email_outlined, '이메일', order.userEmail.isNotEmpty ? order.userEmail : '-'),
                        _detailRow(Icons.location_on_outlined, '배송지', order.userAddress.isNotEmpty ? order.userAddress : '-'),
                      ]),
                      const SizedBox(height: 12),
                      // 주문 상품
                      const Text('주문 상품',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 8),
                      ...order.items.map((item) {
                        // 주문 타입 배지: orderType 기준으로만 판별
                        // item.size == '단체'는 단체주문 폼의 레거시값 — 타입 판별에 사용 안 함
                        final typeLabel = order.orderType == 'additional'
                            ? '추가제작'
                            : order.orderType == 'group'
                                ? '단체'
                                : '개인';
                        final typeColor = order.orderType == 'additional'
                            ? const Color(0xFFC62828)
                            : order.orderType == 'group'
                                ? const Color(0xFF6A1B9A)
                                : const Color(0xFF1565C0);
                        // 표시할 사이즈: '단체'/'GROUP'은 의미없는 값이므로 숨김
                        final displaySize = (item.size == '단체' || item.size == 'GROUP' || item.size.isEmpty)
                            ? null
                            : item.size;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // 주문 타입 배지 (개인/단체/추가제작)
                                  _miniTag(typeLabel, typeColor),
                                  const SizedBox(width: 4),
                                  // 색상
                                  if (item.color.isNotEmpty)
                                    _miniTag(item.color, const Color(0xFFE65100)),
                                  // 사이즈 (개인주문만, '단체' 값 제외)
                                  if (displaySize != null) ...[
                                    const SizedBox(width: 4),
                                    _miniTag(displaySize, const Color(0xFF2E7D32)),
                                  ],
                                  const Spacer(),
                                  Text('${item.quantity}개',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text(' · ${_fmtPrice(item.price * item.quantity)}원',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888))),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      // 결제 정보
                      _detailSection('결제 정보', [
                        _detailRow(Icons.payments_outlined, '결제 방법', order.paymentMethod),
                        _detailRow(Icons.local_shipping_outlined, '배송비', '${_fmtPrice(order.shippingFee)}원'),
                        _detailRow(Icons.receipt_outlined, '합계', '${_fmtPrice(order.totalAmount)}원'),
                        if (order.memo != null && order.memo!.isNotEmpty)
                          _detailRow(Icons.notes_outlined, '메모', order.memo!),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportPersonalOrderExcel(order);
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('엑셀 내보내기',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: const Color(0xFF00897B),
                          side: const BorderSide(color: Color(0xFF00897B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('닫기',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              // 결제완료 버튼 (무통장입금 + pending 상태일 때)
              if (currentOrder.paymentMethod == '무통장입금' &&
                  currentOrder.status == OrderStatus.pending)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('결제 확인', style: TextStyle(fontWeight: FontWeight.w800)),
                            content: Text(
                              '${currentOrder.userName} 님의 주문\n(${_fmtPrice(currentOrder.totalAmount)}원) 입금을 확인하고\n결제완료로 변경하시겠습니까?',
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('결제완료 확인', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await OrderService.updateOrderStatus(currentOrder.id, OrderStatus.confirmed);
                          context.read<OrderProvider>().updateOrderStatus(currentOrder.id, OrderStatus.confirmed);
                          FcmService.sendOrderStatusNotification(
                            userId: currentOrder.userId,
                            orderId: currentOrder.id,
                            newStatus: OrderStatus.confirmed,
                          );
                          setDlgState(() {
                            currentOrder = currentOrder.copyWith(status: OrderStatus.confirmed);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('결제완료로 변경되었습니다.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('입금 확인 → 결제완료로 변경',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
          );
        },
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF888888)),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }

  // ── 단체주문 팀원 명단 상세보기 ──
  /// gender 영문 → 한글 변환 (male→남, female→여)
  String _normalizeGender(dynamic g) {
    if (g == null) return '-';
    final s = g.toString().toLowerCase();
    if (s == 'male' || s == 'm' || s == '남성') return '남';
    if (s == 'female' || s == 'f' || s == '여성') return '여';
    return g.toString();
  }

  void _showGroupOrderDetail(OrderModel order) {
    OrderModel currentOrder = order;
    final opts = order.customOptions ?? {};
    final rawPersons = (opts['persons'] as List<dynamic>?) ?? [];
    // gender 정규화
    final persons = rawPersons.map((p) {
      if (p is Map) {
        final m = Map<String, dynamic>.from(p);
        m['gender'] = _normalizeGender(m['gender']);
        return m;
      }
      return p as Map<String, dynamic>;
    }).toList();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '단체주문 상세: ${opts['teamName'] ?? order.id}',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _whiteTag('${opts['totalCount'] ?? order.groupCount ?? persons.length}명'),
                        if ((opts['printTypeLabel'] ?? opts['printType'] ?? '').toString().isNotEmpty)
                          _whiteTag((opts['printTypeLabel'] ?? opts['printType']).toString()),
                        if ((opts['mainColor'] ?? '').toString().isNotEmpty)
                          _whiteTag('색상: ${opts['mainColor']}'),
                        if ((opts['fabricType'] ?? opts['fabric'] ?? '').toString().isNotEmpty)
                          _whiteTag((opts['fabricType'] ?? opts['fabric']).toString()),
                      ],
                    ),
                  ],
                ),
              ),
              // 기본 정보
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFF5F5F5),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _infoChip(Icons.person, '담당자', opts['manager']?.toString() ?? opts['managerName']?.toString() ?? order.userName),
                    _infoChip(Icons.phone, '연락처', order.userPhone.isNotEmpty ? order.userPhone : '-'),
                    _infoChip(Icons.location_on, '배송지', order.userAddress.isNotEmpty ? order.userAddress : '-'),
                    _infoChip(Icons.male, '남', '${opts['maleCount'] ?? persons.where((p) => (p as Map)['gender'] == '남').length}명'),
                    _infoChip(Icons.female, '여', '${opts['femaleCount'] ?? persons.where((p) => (p as Map)['gender'] == '여').length}명'),
                    if ((opts['waistbandOption'] ?? opts['waistband'] ?? '').toString().isNotEmpty)
                      _infoChip(Icons.style, '허리밴드', (opts['waistbandOption'] ?? opts['waistband']).toString()),
                  ],
                ),
              ),
              // 팀원 명단 테이블
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: persons.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('팀원 명단 정보가 없습니다.', style: TextStyle(color: Color(0xFF888888))),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('팀원 명단 (${persons.length}명)',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            // 테이블 헤더
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 30, child: Text('No', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                                  Expanded(flex: 2, child: Text('이름', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                                  SizedBox(width: 36, child: Text('성별', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                                  Expanded(child: Text('상의', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                                  Expanded(child: Text('하의', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                                ],
                              ),
                            ),
                            ...persons.asMap().entries.map((entry) {
                              final i = entry.key;
                              final p = entry.value as Map<String, dynamic>;
                              final isEven = i % 2 == 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                color: isEven ? const Color(0xFFF5F5F5) : Colors.white,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Text('${p['index'] ?? i + 1}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(p['name']?.toString() ?? '-',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                    SizedBox(
                                      width: 36,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p['gender'] == '남' ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(p['gender']?.toString() ?? '-',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: p['gender'] == '남' ? const Color(0xFF1565C0) : const Color(0xFFC62828))),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(p['topSize']?.toString() ?? '-',
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                    Expanded(
                                      child: Text(p['bottomSize']?.toString() ?? '-',
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ),
              // 하단 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportGroupOrderExcel(order);
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('엑셀 내보내기', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: const Color(0xFF00897B),
                          side: const BorderSide(color: Color(0xFF00897B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('닫기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              // 결제완료 버튼 (무통장입금 + pending 상태일 때)
              if (currentOrder.paymentMethod == '무통장입금' &&
                  currentOrder.status == OrderStatus.pending)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('결제 확인', style: TextStyle(fontWeight: FontWeight.w800)),
                            content: Text(
                              '${currentOrder.groupName ?? currentOrder.userName} 단체 주문\n(${_fmtPrice(currentOrder.totalAmount)}원) 입금을 확인하고\n결제완료로 변경하시겠습니까?',
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('결제완료 확인', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await OrderService.updateOrderStatus(currentOrder.id, OrderStatus.confirmed);
                          context.read<OrderProvider>().updateOrderStatus(currentOrder.id, OrderStatus.confirmed);
                          FcmService.sendOrderStatusNotification(
                            userId: currentOrder.userId,
                            orderId: currentOrder.id,
                            newStatus: OrderStatus.confirmed,
                          );
                          setDlgState(() {
                            currentOrder = currentOrder.copyWith(status: OrderStatus.confirmed);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('결제완료로 변경되었습니다.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('입금 확인 → 결제완료로 변경',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _whiteTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF888888)),
        const SizedBox(width: 3),
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
      ],
    );
  }

  // ── 개인 주문 엑셀 내보내기 ──
  Future<void> _exportPersonalOrderExcel(OrderModel order) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('엑셀 생성 중...'),
          ]),
          duration: Duration(seconds: 10),
          backgroundColor: Color(0xFF1A1A2E),
        ),
      );
    }
    try {
      final now = DateTime.now();
      final bytes = await OrderExcelService.generateSelectedOrdersExcel([order], now);
      final dateStr =
          '${order.createdAt.month.toString().padLeft(2, '0')}${order.createdAt.day.toString().padLeft(2, '0')}';
      final safeName = order.userName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '주문_${safeName}_$dateStr.xlsx';
      const mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      if (kIsWeb) {
        downloadFileWeb(bytes, fileName, mimeType);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      const Text('📂 다운로드 폴더에서 확인하세요',
                          style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ]),
              backgroundColor: const Color(0xFF00897B),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await Share.shareXFiles(
          [XFile(filePath, mimeType: mimeType, name: fileName)],
          subject: '2FIT 주문 ${order.userName} 엑셀',
          text: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('엑셀 생성 오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── 단체주문 개별 엑셀 내보내기 (디자인 이미지 + 모든 필드 포함) ──
  Future<void> _exportGroupOrderExcel(OrderModel order) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('엑셀 생성 중...'),
          ]),
          duration: Duration(seconds: 10),
          backgroundColor: Color(0xFF4A148C),
        ),
      );
    }
    try {
      final bytes = await OrderExcelService.generateGroupOrderExcelAsync(order);
      final teamName = (order.customOptions?['teamName'] as String?)?.replaceAll(' ', '_') ?? order.id;
      final dateStr = '${order.createdAt.month.toString().padLeft(2,'0')}${order.createdAt.day.toString().padLeft(2,'0')}';
      final fileName = '단체주문_${teamName}_$dateStr.xlsx';
      final mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      if (kIsWeb) {
        downloadFileWeb(bytes, fileName, mimeType);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const Text('📂 화면 하단 다운로드 바 또는 내 PC → 다운로드 폴더 확인',
                          style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ]),
              backgroundColor: const Color(0xFF00897B),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } else {
        // 모바일: 바로 공유 시트 열기
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await Share.shareXFiles(
          [XFile(filePath, mimeType: mimeType, name: fileName)],
          subject: '2FIT 단체주문 ${teamName.replaceAll('_', ' ')} 엑셀',
          text: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('엑셀 생성 오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ══════════════════════════════════════════════
  // TAB 3 : 상품 관리
  // ══════════════════════════════════════════════
  Widget _buildProductManagement() {
    final allProducts = context.watch<ProductProvider>().adminProducts;
    final isAdminLoading = context.watch<ProductProvider>().isAdminLoading;

    // 검색 + 카테고리 필터 적용
    var filtered = _productCategoryFilter == '전체'
        ? allProducts
        : allProducts.where((p) => p.category == _productCategoryFilter).toList();
    if (_productSearchQuery.isNotEmpty) {
      final q = _productSearchQuery.toLowerCase();
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    final allSelected = filtered.isNotEmpty &&
        filtered.every((p) => _selectedProductIds.contains(p.id));
    final anySelected = _selectedProductIds.isNotEmpty;

    return Column(
      children: [
        // 로딩 중 프로그레스바
        if (isAdminLoading)
          const LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: Color(0xFFEEEEEE),
            color: Color(0xFF1A1A2E),
          ),
        // 툴바
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => setState(() {
                    _productSearchQuery = v;
                    _selectedProductIds.clear();
                  }),
                  decoration: InputDecoration(
                    hintText: '상품명 검색...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFFBBBBBB)),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 새로고침 버튼
              IconButton(
                onPressed: () => context.read<ProductProvider>().loadAdminProducts(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: '상품 새로고침',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  fixedSize: const Size(40, 40),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('상품 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        // 카테고리 필터
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['전체', '상의', '하의', '세트', '아우터', '스킨슈트', '악세사리', '이벤트']
                  .map((cat) => GestureDetector(
                        onTap: () => setState(() {
                          _productCategoryFilter = cat;
                          _selectedProductIds.clear();
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: cat == _productCategoryFilter
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                fontSize: 12,
                                color: cat == _productCategoryFilter
                                    ? Colors.white
                                    : const Color(0xFF555555),
                                fontWeight: cat == _productCategoryFilter
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              )),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        // 전체선택 + 일괄삭제 툴바
        Container(
          color: const Color(0xFFF4F6FA),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            // 전체선택 체크박스
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSelected) {
                    _selectedProductIds.removeAll(filtered.map((p) => p.id));
                  } else {
                    _selectedProductIds.addAll(filtered.map((p) => p.id));
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    allSelected
                        ? Icons.check_box_rounded
                        : _selectedProductIds.isEmpty
                            ? Icons.check_box_outline_blank_rounded
                            : Icons.indeterminate_check_box_rounded,
                    color: const Color(0xFF1A1A2E),
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  const Text('전체선택',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('총 ${filtered.length}개 · 선택 ${_selectedProductIds.length}개',
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
            const Spacer(),
            // 선택 삭제 버튼
            if (anySelected)
              GestureDetector(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(children: [
                        Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 22),
                        SizedBox(width: 8),
                        Text('상품 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                      content: Text('선택한 ${_selectedProductIds.length}개 상품을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    final idsToDelete = Set<String>.from(_selectedProductIds);
                    final productProvider = context.read<ProductProvider>();
                    for (final id in idsToDelete) {
                      await productProvider.deleteProduct(id);
                    }
                    setState(() => _selectedProductIds.clear());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${idsToDelete.length}개 상품이 삭제되었습니다'),
                          backgroundColor: const Color(0xFF1A1A2E),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.delete_sweep_rounded, color: Color(0xFFE53935), size: 14),
                    SizedBox(width: 4),
                    Text('선택삭제', style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: isAdminLoading ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC)),
                      const SizedBox(height: 12),
                      Text(
                        isAdminLoading ? '상품 목록을 불러오는 중...' : '상품이 없습니다',
                        style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                      ),
                      if (!isAdminLoading) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => context.read<ProductProvider>().loadAdminProducts(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('다시 불러오기'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _productCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _productCard(ProductModel p) {
    final isSelected = _selectedProductIds.contains(p.id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedProductIds.remove(p.id);
          } else {
            _selectedProductIds.add(p.id);
          }
        });
      },
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8EAF6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // 체크박스
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
              size: 18,
            ),
          ),
          const SizedBox(width: 6),
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              p.images.first,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.checkroom_rounded,
                    color: Color(0xFFCCCCCC)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.category} · ${_fmtPrice(p.price)}원',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (p.isNew) _miniTag('NEW', const Color(0xFF1565C0)),
                      if (p.isSale)
                        _miniTag('SALE', const Color(0xFFE53935)),
                      if (p.isFreeShipping)
                        _miniTag('무료배송', const Color(0xFF43A047)),
                      const Spacer(),
                      // 재고
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.stockCount > 10
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('재고 ${p.stockCount}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.stockCount > 10
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE53935))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 18, color: Color(0xFF888888)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('수정')
                  ])),
              const PopupMenuItem(
                  value: 'stock',
                  child: Row(children: [
                    Icon(Icons.inventory_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('재고 수정')
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Color(0xFFE53935)),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Color(0xFFE53935)))
                  ])),
            ],
            onSelected: (val) {
              if (val == 'edit') {
                _showEditProductDialog(p);
              } else if (val == 'stock') {
                _showStockDialog(p);
              } else if (val == 'delete') {
                _showDeleteProductDialog(p);
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    ));
  }

  // ══════════════════════════════════════════════
  // TAB 4 : 배너 관리
  // ══════════════════════════════════════════════
  Widget _buildBannerManagement() {
    final banners = _bannerItems;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('홈 메인 배너',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddBannerDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('배너 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: banners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final b = banners[i];
              final isActive = b['active'] as bool;
              return Container(
                decoration: _cardDeco(),
                child: Column(
                  children: [
                    // 배너 미리보기
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(14)),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1A1A1A),
                            Color(0xFF3D3D3D)
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                b['tag'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b['title'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['title'] as String,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Text('순서 ${b['order']}번',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888))),
                            ],
                          ),
                          const Spacer(),
                          // 활성 토글
                          Row(
                            children: [
                              Text(
                                isActive ? '활성' : '비활성',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? const Color(0xFF43A047)
                                        : const Color(0xFFAAAAAA)),
                              ),
                              const SizedBox(width: 6),
                              Switch(
                                value: isActive,
                                onChanged: (val) {
                                  setState(() => _bannerItems[i]['active'] = val);
                                },
                                activeThumbColor: const Color(0xFF43A047),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          _iconBtn(Icons.edit_outlined, () {
                            _showEditBannerDialog(i, b);
                          }),
                          const SizedBox(width: 4),
                          _iconBtn(Icons.delete_outline, () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('배너 삭제'),
                                content: Text('\'${b['title']}\' 배너를 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _bannerItems.removeAt(i));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('배너가 삭제되었습니다.'), backgroundColor: Color(0xFF1A1A2E)),
                                      );
                                    },
                                    child: const Text('삭제', style: TextStyle(color: Color(0xFFE53935))),
                                  ),
                                ],
                              ),
                            );
                          },
                              color: const Color(0xFFE53935)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // TAB 5 : 회원 관리 (Firestore 실시간)
  // ══════════════════════════════════════════════
  Widget _buildMemberManagement() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AuthService.watchAllUsers(),
      initialData: _cachedMembers,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE53935)),
                const SizedBox(height: 12),
                Text('회원 데이터 로드 실패: ${snapshot.error}', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text('다시 시도')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          // 캐시 데이터 없을 때만 로딩 표시 (initialData로 대부분 건너뜀)
          return Container(
            color: const Color(0xFFF4F6FA),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E))),
          );
        }
        final allMembers = snapshot.data ?? [];

        // 검색 필터 적용
        final members = _memberSearchQuery.isEmpty
            ? allMembers
            : allMembers.where((m) {
                final q = _memberSearchQuery.toLowerCase();
                final name = (m['name'] as String? ?? '').toLowerCase();
                final email = (m['email'] as String? ?? '').toLowerCase();
                return name.contains(q) || email.contains(q);
              }).toList();

        final allSelected = members.isNotEmpty &&
            members.every((m) => _selectedMemberIds.contains(m['uid'] as String? ?? m['id'] as String? ?? ''));
        final anySelected = _selectedMemberIds.isNotEmpty;

        return Column(
          children: [
            // ── 검색바 ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: TextField(
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => setState(() {
                  _memberSearchQuery = v;
                  _selectedMemberIds.clear();
                }),
                decoration: InputDecoration(
                  hintText: '회원명 / 이메일 검색...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // ── 전체선택 + 일괄삭제 툴바 ──
            Container(
              color: const Color(0xFFF4F6FA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          _selectedMemberIds.removeAll(members.map((m) => m['uid'] as String? ?? m['id'] as String? ?? ''));
                        } else {
                          _selectedMemberIds.addAll(members.map((m) => m['uid'] as String? ?? m['id'] as String? ?? ''));
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          allSelected
                              ? Icons.check_box_rounded
                              : _selectedMemberIds.isEmpty
                                  ? Icons.check_box_outline_blank_rounded
                                  : Icons.indeterminate_check_box_rounded,
                          color: const Color(0xFF1A1A2E),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        const Text('전체선택',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '총 ${members.length}명 · 선택 ${_selectedMemberIds.length}명',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                  const Spacer(),
                  // 등급 일괄변경
                  if (anySelected)
                    GestureDetector(
                      onTap: () => _showBulkGradeChangeDialog(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.star_rounded, color: Color(0xFFE65100), size: 14),
                          SizedBox(width: 4),
                          Text('등급변경', style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  // 선택 삭제
                  if (anySelected)
                    GestureDetector(
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(children: [
                              Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 22),
                              SizedBox(width: 8),
                              Text('회원 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
                            ]),
                            content: Text('선택한 ${_selectedMemberIds.length}명의 회원 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && mounted) {
                          for (final uid in _selectedMemberIds.toList()) {
                            await AuthService.deleteUserDocument(uid);
                          }
                          setState(() => _selectedMemberIds.clear());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('선택한 회원이 삭제되었습니다'), backgroundColor: Color(0xFF1A1A2E)),
                          );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.delete_sweep_rounded, color: Color(0xFFE53935), size: 14),
                          SizedBox(width: 4),
                          Text('선택삭제', style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: members.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 12),
                          Text('회원이 없습니다', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m = members[i];
                        final memberId = m['uid'] as String? ?? m['id'] as String? ?? '';
                        final isSelected = _selectedMemberIds.contains(memberId);
                        final grade = m['memberTier'] as String? ?? m['grade'] as String? ?? '일반';
                        final isBlocked = m['isBlocked'] as bool? ?? false;
                        final gradeColor = grade == 'VIP' || grade == 'vip'
                            ? const Color(0xFFE65100)
                            : grade == '신규' || grade == 'bronze'
                                ? const Color(0xFF1565C0)
                                : const Color(0xFF555555);
                        final name = m['name'] as String? ?? '이름없음';
                        final email = m['email'] as String? ?? '';
                        final createdAt = m['createdAt'] is Timestamp
                            ? (m['createdAt'] as Timestamp).toDate()
                            : m['createdAt'] is String
                                ? DateTime.tryParse(m['createdAt'] as String) ?? DateTime(2000)
                                : DateTime(2000);
                        final joinDate =
                            '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
                        final isAdmin = m['isAdmin'] as bool? ?? false;

                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedMemberIds.remove(memberId);
                            } else {
                              _selectedMemberIds.add(memberId);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE8EAF6)
                                  : isBlocked
                                      ? const Color(0xFFFFF3F3)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1A1A2E)
                                    : isBlocked
                                        ? const Color(0xFFFFCDD2)
                                        : const Color(0xFFEEEEEE),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? []
                                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isSelected
                                      ? const Color(0xFF1A1A2E)
                                      : gradeColor.withValues(alpha: 0.15),
                                  child: Text(
                                    name.isNotEmpty ? name[0] : '?',
                                    style: TextStyle(
                                        color: isSelected ? Colors.white : gradeColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: gradeColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(grade,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: gradeColor)),
                                          ),
                                          if (isAdmin) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1A1A2E).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('관리자',
                                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                                            ),
                                          ],
                                          if (isBlocked) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('차단',
                                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(email,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                      Text(
                                        '가입일 $joinDate',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF888888)),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'view', child: Text('주문 내역')),
                                    const PopupMenuItem(value: 'grade', child: Text('등급 변경')),
                                    const PopupMenuItem(value: 'memo', child: Text('메모')),
                                    PopupMenuItem(
                                        value: 'block',
                                        child: Text(
                                          isBlocked ? '차단 해제' : '계정 차단',
                                          style: TextStyle(color: isBlocked ? Colors.green : const Color(0xFFE53935)),
                                        )),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'view') {
                                      _showMemberOrdersDialog(m);
                                    } else if (val == 'grade') {
                                      _showMemberGradeDialog(m);
                                    } else if (val == 'block') {
                                      _showMemberBlockDialog(m);
                                    } else if (val == 'memo') {
                                      _showMemberMemoDialog(m);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── 프로모션 알림 발송 다이얼로그 ─────────────────────────
  void _showPromoNotificationDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? selectedGrade; // null = 전체
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF6F00), size: 18),
              ),
              const SizedBox(width: 8),
              const Text('푸시 알림 발송', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 대상 선택
                const Text('발송 대상', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedGrade,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('전체 회원')),
                        DropdownMenuItem(value: '신규', child: Text('신규 회원')),
                        DropdownMenuItem(value: '일반', child: Text('일반 회원')),
                        DropdownMenuItem(value: 'VIP', child: Text('VIP 회원')),
                        DropdownMenuItem(value: 'VVIP', child: Text('VVIP 회원')),
                      ],
                      onChanged: (v) => setS(() => selectedGrade = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('알림 제목', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: '예: 🎉 신상품 출시 알림',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('알림 내용', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '예: 2FIT 여름 신상품이 입고되었습니다. 지금 확인해보세요!',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Firestore fcm_queue를 통해 FCM 알림이 발송됩니다.\nFCM 프로세서(fcm_processor.py)가 실행 중이어야 합니다.',
                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton.icon(
              onPressed: isSending ? null : () async {
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림 제목을 입력하세요')),
                  );
                  return;
                }
                setS(() => isSending = true);
                try {
                  final success = await FcmService.sendPromoNotification(
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim().isEmpty
                        ? '2FIT Mall에서 새로운 소식을 전달드립니다.'
                        : bodyCtrl.text.trim(),
                    targetGrade: selectedGrade,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? '✅ 알림이 발송되었습니다'
                            : '⚠️ 알림 발송 실패'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  setS(() => isSending = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(isSending ? '발송 중...' : '발송'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 회원 등급 일괄변경 다이얼로그
  void _showBulkGradeChangeDialog() {
    String? selectedGrade;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.star_rounded, color: Color(0xFFE65100), size: 22),
            SizedBox(width: 8),
            Text('일괄 등급 변경', style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('선택된 ${_selectedMemberIds.length}명의 등급을 변경합니다.'),
              const SizedBox(height: 16),
              ...['신규', '일반', 'VIP'].map((g) => RadioListTile<String>(
                value: g,
                groupValue: selectedGrade,
                onChanged: (v) => setD(() => selectedGrade = v),
                title: Text(g, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                dense: true,
                activeColor: const Color(0xFF1A1A2E),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: selectedGrade == null ? null : () async {
                Navigator.pop(ctx);
                // Firestore에서 선택된 모든 회원 등급 일괄 변경
                for (final uid in _selectedMemberIds.toList()) {
                  await AuthService.updateUserGrade(uid, selectedGrade!);
                }
                if (mounted) {
                  setState(() => _selectedMemberIds.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$selectedGrade" 등급으로 변경 완료'), backgroundColor: const Color(0xFF1A1A2E)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 공통 헬퍼 위젯
  // ══════════════════════════════════════════════

  // 빈 상태 / 에러 상태 공통 위젯
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      color: const Color(0xFFF4F6FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFFBBBBBB)),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(sub, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _salesRow(String period, String amount, String change, bool isPos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Text(period, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)), overflow: TextOverflow.ellipsis),
          ),
          const Spacer(),
          Flexible(
            flex: 3,
            child: Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isPos ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(change, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPos ? const Color(0xFF2E7D32) : const Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _orderTypeCard(String label, int pct, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: pct / 100,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 5,
                ),
              ),
              Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 주문 유형 가로 바 스타일 (새 대시보드용)
  Widget _orderTypeRow(String label, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _recentOrderRow(OrderModel order) {
    final sc = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: _cardDeco(),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(order.userName, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(order.status.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sc)),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 2,
            child: Text('${_fmtPrice(order.totalAmount)}원', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF1A1A2E)),
        const SizedBox(width: 5),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      ],
    );
  }

  // ignore: unused_element
  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // 가로 리스트 스타일 빠른 작업 (새 대시보드용)
  Widget _quickActionRow(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
            Icon(Icons.chevron_right_rounded, size: 14, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }


  // ignore: unused_element
  Widget _fl(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, color: Color(0xFF444444))));

  // ignore: unused_element
  Widget _ff(TextEditingController c, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
        filled: true, fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)));
  }

  // ignore: unused_element
  Widget _tChip(String label, bool val, ValueChanged<bool> cb,
      {Color ac = const Color(0xFF1A1A2E)}) {
    return GestureDetector(
      onTap: () => cb(!val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: val ? ac.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: val ? ac : const Color(0xFFDDDDDD),
              width: val ? 1.5 : 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(val ? Icons.check_circle : Icons.circle_outlined,
              size: 14, color: val ? ac : const Color(0xFFAAAAAA)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12,
              fontWeight: val ? FontWeight.w700 : FontWeight.w400,
              color: val ? ac : const Color(0xFF777777))),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = const Color(0xFF555555)}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF0F0F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));

  void _showEditBannerDialog(int index, Map<String, dynamic> b) {
    final titleCtrl = TextEditingController(text: b['title'] as String);
    Uint8List? pickedBytes;
    bool isUploading = false;
    final existingUrl = (b['imageUrl'] ?? '') as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('배너 편집', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: '배너 제목',
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('배너 이미지', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isUploading ? null : () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1400);
                  if (file == null) return;
                  final bytes = await file.readAsBytes();
                  setDlg(() => pickedBytes = bytes);
                },
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: pickedBytes != null
                        ? Stack(children: [
                            Image.memory(pickedBytes!, width: double.infinity, height: 140, fit: BoxFit.cover),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setDlg(() => pickedBytes = null),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ])
                        : existingUrl.isNotEmpty
                            ? Stack(children: [
                                Image.network(existingUrl, width: double.infinity, height: 140, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Color(0xFFCCCCCC))),
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    color: Colors.black38,
                                    child: const Text('탭하여 이미지 교체', textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ])
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFFBBBBBB)),
                                  SizedBox(height: 6),
                                  Text('탭하여 이미지 선택', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                                ],
                              ),
                  ),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
              onPressed: isUploading ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                String? newUrl;
                if (pickedBytes != null) {
                  setDlg(() => isUploading = true);
                  newUrl = await StorageService.uploadBannerImage(
                    bannerId: 'banner_${index}_${DateTime.now().millisecondsSinceEpoch}',
                    imageBytes: pickedBytes!,
                  );
                }
                setState(() {
                  _bannerItems[index]['title'] = titleCtrl.text.trim();
                  if (newUrl != null) _bannerItems[index]['imageUrl'] = newUrl;
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('배너가 수정되었습니다'), backgroundColor: Color(0xFF1A1A2E)));
                }
              },
              child: isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('저장', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _showAddBannerDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl   = TextEditingController();
    Uint8List? pickedBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('배너 추가', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: '배너 제목',
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
              const SizedBox(height: 12),
              // ── 이미지 업로드 영역 ──
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('배너 이미지', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isUploading ? null : () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1400);
                  if (file == null) return;
                  final bytes = await file.readAsBytes();
                  setDlg(() { pickedBytes = bytes; urlCtrl.clear(); });
                },
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: pickedBytes != null
                        ? Stack(children: [
                            Image.memory(pickedBytes!, width: double.infinity, height: 140, fit: BoxFit.cover),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setDlg(() => pickedBytes = null),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ])
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFFBBBBBB)),
                              SizedBox(height: 6),
                              Text('탭하여 이미지 선택', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                              SizedBox(height: 2),
                              Text('또는 아래 URL 직접 입력', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // URL 직접 입력 (선택)
              TextField(
                controller: urlCtrl,
                enabled: pickedBytes == null,
                decoration: InputDecoration(
                  hintText: 'URL 직접 입력 (이미지 선택 시 무시됨)',
                  hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                  filled: true, fillColor: pickedBytes != null ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
              onPressed: isUploading ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                String imageUrl = urlCtrl.text.trim();
                if (pickedBytes != null) {
                  setDlg(() => isUploading = true);
                  final uploaded = await StorageService.uploadBannerImage(
                    bannerId: 'banner_new_${DateTime.now().millisecondsSinceEpoch}',
                    imageBytes: pickedBytes!,
                  );
                  imageUrl = uploaded ?? '';
                }
                setState(() {
                  _bannerItems.add({
                    'title': titleCtrl.text.trim(),
                    'tag': 'NEW',
                    'active': true,
                    'order': _bannerItems.length + 1,
                    'imageUrl': imageUrl,
                  });
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('배너가 추가되었습니다'), backgroundColor: Color(0xFF1A1A2E)));
                }
              },
              child: isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('추가', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductFormDialog(null);
  }

  void _showEditProductDialog(ProductModel p) {
    _showProductFormDialog(p);
  }

  void _showProductFormDialog(ProductModel? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductFormDialog(
        existing: existing,
        onSaved: (product, isEdit) async {
          if (isEdit) {
            await context.read<ProductProvider>().updateProduct(product);
          } else {
            await context.read<ProductProvider>().addProduct(product);
          }
          if (mounted) setState(() {});
        },
      ),
    );
  }

  // ── 재고 수정 다이얼로그
  void _showStockDialog(ProductModel p) {
    final ctrl = TextEditingController(text: p.stockCount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('재고 수정', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(p.name, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '재고 수량', suffixText: '개',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
            onPressed: () async {
              final newStock = int.tryParse(ctrl.text) ?? p.stockCount;
              await ProductService.updateStock(p.id, newStock);
              await context.read<ProductProvider>().refresh();
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('\${p.name} 재고가 \${newStock}개로 업데이트되었습니다'),
                  backgroundColor: Color(0xFF1A1A2E)));
              }
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 배송 정보 입력 다이얼로그 (배송중 상태 변경 시)
  Future<void> _showShippingDialog(String orderId, OrderStatus newStatus) async {
    final trackingCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.local_shipping_outlined, color: Color(0xFF1A1A2E), size: 22),
          SizedBox(width: 8),
          Text('배송 정보 입력', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyCtrl,
              decoration: InputDecoration(
                labelText: '택배사',
                hintText: '예: CJ대한통운, 롯데택배',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingCtrl,
              decoration: InputDecoration(
                labelText: '운송장 번호',
                hintText: '숫자만 입력',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoCtrl,
              decoration: InputDecoration(
                labelText: '관리자 메모 (선택)',
                hintText: '내부 참고용',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              await OrderService.updateOrderStatusWithTracking(
                orderId: orderId,
                status: newStatus,
                trackingNumber: trackingCtrl.text.trim().isEmpty ? null : trackingCtrl.text.trim(),
                shippingCompany: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                adminMemo: memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim(),
              );
              // FCM 푸시 알림 (배송 시작)
              final allOrders = context.read<OrderProvider>().orders;
              final targetOrder = allOrders.firstWhere(
                (o) => o.id == orderId,
                orElse: () => allOrders.first,
              );
              if (targetOrder.id == orderId) {
                FcmService.sendOrderStatusNotification(
                  order: targetOrder,
                  newStatus: newStatus,
                ).catchError((e) {
                  if (kDebugMode) debugPrint('⚠️ FCM 알림 실패: $e');
                });
              }
              if (mounted) {
                context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('배송 정보 저장 완료 🔔알림 전송 (운송장: ${trackingCtrl.text.isEmpty ? "미입력" : trackingCtrl.text})'),
                    backgroundColor: const Color(0xFF1A1A2E),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    trackingCtrl.dispose();
    companyCtrl.dispose();
    memoCtrl.dispose();
  }

  // ── 상품 삭제 다이얼로그
  void _showDeleteProductDialog(ProductModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('상품 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('"\${p.name}"을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () async {
              await context.read<ProductProvider>().deleteProduct(p.id);
              Navigator.pop(ctx);
              if (mounted) {
                setState(() { _selectedProductIds.remove(p.id); });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('\${p.name}이(가) 삭제되었습니다'),
                  backgroundColor: Color(0xFFE53935)));
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 회원 주문내역 다이얼로그
  void _showMemberOrdersDialog(Map<String, dynamic> m) {
    final uid = m['uid'] as String? ?? '';
    final name = m['name'] as String? ?? '회원';
    final email = m['email'] as String? ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.receipt_long_outlined, size: 20, color: Color(0xFF1A1A2E)),
          const SizedBox(width: 8),
          Text('$name 주문내역', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        content: SizedBox(
          width: 360,
          height: 300,
          child: uid.isEmpty
              ? const Center(child: Text('회원 정보를 불러올 수 없습니다'))
              : FutureBuilder<List<OrderModel>>(
                  future: OrderService.getUserOrders(uid),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final orders = snap.data ?? [];
                    if (orders.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCCCCCC)),
                          const SizedBox(height: 8),
                          Text('$name님의 주문이 없습니다', style: const TextStyle(color: Color(0xFF999999))),
                          const SizedBox(height: 8),
                          Text('이메일: $email', style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                        ],
                      );
                    }
                    return ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final o = orders[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(o.status.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                          ),
                          title: Text(o.items.map((i) => i.productName).join(', '),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${_fmtPrice(o.totalAmount)}원 · ${_fmtDate(o.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  // ── 회원 등급 변경 다이얼로그 (Firestore 연동)
  void _showMemberGradeDialog(Map<String, dynamic> m) {
    final uid = m['uid'] as String? ?? '';
    final name = m['name'] as String? ?? '회원';
    String selectedGrade = m['memberTier'] as String? ?? m['grade'] as String? ?? '일반';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFE65100), size: 20),
            const SizedBox(width: 8),
            Text('$name 등급 변경', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final grade in ['신규', '일반', 'VIP', 'VVIP'])
              RadioListTile<String>(
                value: grade,
                groupValue: selectedGrade,
                onChanged: (v) { if (v != null) setS(() { selectedGrade = v; }); },
                title: Text(grade, style: const TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
              onPressed: () async {
                Navigator.pop(ctx);
                await AuthService.updateUserGrade(uid, selectedGrade);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name 등급이 $selectedGrade(으)로 변경되었습니다'), backgroundColor: const Color(0xFF1A1A2E)),
                );
                }
              },
              child: const Text('변경', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 계정 차단/해제 다이얼로그 (Firestore 연동)
  void _showMemberBlockDialog(Map<String, dynamic> m) {
    final uid = m['uid'] as String? ?? '';
    final name = m['name'] as String? ?? '회원';
    final isBlocked = m['isBlocked'] as bool? ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
              color: isBlocked ? Colors.green : const Color(0xFFE53935), size: 20),
          const SizedBox(width: 8),
          Text(isBlocked ? '계정 차단 해제' : '계정 차단',
              style: TextStyle(fontWeight: FontWeight.w800, color: isBlocked ? Colors.green : const Color(0xFFE53935))),
        ]),
        content: Text(
          isBlocked
              ? '"$name" 계정의 차단을 해제하시겠습니까?'
              : '"$name" 계정을 차단하시겠습니까?\n차단 시 해당 계정은 로그인이 제한됩니다.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : const Color(0xFFE53935),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.updateUserBlocked(uid, !isBlocked);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isBlocked ? '$name 차단이 해제되었습니다' : '$name 계정이 차단되었습니다'),
                  backgroundColor: isBlocked ? Colors.green : const Color(0xFFE53935),
                ),
              );
              }
            },
            child: Text(isBlocked ? '해제' : '차단', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 회원 메모 다이얼로그
  void _showMemberMemoDialog(Map<String, dynamic> m) {
    final uid = m['uid'] as String? ?? '';
    final name = m['name'] as String? ?? '회원';
    final memoCtrl = TextEditingController(text: m['adminMemo'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.note_alt_outlined, color: Color(0xFF1A1A2E), size: 20),
          const SizedBox(width: 8),
          Text('$name 관리자 메모', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        content: TextField(
          controller: memoCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '내부 참고용 메모를 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () { memoCtrl.dispose(); Navigator.pop(ctx); }, child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
            onPressed: () async {
              final memo = memoCtrl.text.trim();
              memoCtrl.dispose();
              Navigator.pop(ctx);
              await AuthService.updateUserMemo(uid, memo);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메모가 저장되었습니다'), backgroundColor: Color(0xFF1A1A2E)),
              );
              }
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 관리자 알림 다이얼로그 (개선)
  void _showAdminNotifications() {
    AdminNotificationStore.markAllRead();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final notifications = AdminNotificationStore.all;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF1A1A2E)),
              const SizedBox(width: 8),
              const Text('관리자 알림 & 설정', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              // 브라우저 알림 권한 버튼
              if (kIsWeb)
                TextButton.icon(
                  onPressed: () async {
                    final ok = await AdminWebNotifier.requestPermission();
                    setDlgState(() {});
                    if (ok && ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('브라우저 알림이 허용되었습니다 🔔'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  icon: Icon(
                    AdminWebNotifier.isGranted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    size: 14,
                    color: AdminWebNotifier.isGranted ? Colors.green : const Color(0xFFE53935),
                  ),
                  label: Text(
                    AdminWebNotifier.isGranted ? '알림 ON' : '알림 허용',
                    style: TextStyle(
                      fontSize: 11,
                      color: AdminWebNotifier.isGranted ? Colors.green : const Color(0xFFE53935),
                    ),
                  ),
                ),
            ]),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 실시간 알림 목록 ──
                    Row(
                      children: [
                        const Text('최근 알림', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
                        const Spacer(),
                        if (notifications.isNotEmpty)
                          TextButton(
                            onPressed: () { AdminNotificationStore.clear(); setDlgState(() {}); },
                            child: const Text('전체 삭제', style: TextStyle(fontSize: 11, color: Color(0xFFE53935))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (notifications.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text('새 알림이 없습니다', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                          ],
                        ),
                      )
                    else
                      ...notifications.take(10).map((n) => _notifItem(
                        n.type == 'chat' ? Icons.chat_rounded : Icons.shopping_bag_rounded,
                        n.body,
                        _timeAgo(n.time),
                        n.type == 'chat' ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                      )),
                    const Divider(height: 20),
                    // ── 알림 설정 ──
                    const Text('알림 설정', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('새 채팅 문의 알림', style: TextStyle(fontSize: 13)),
                      value: _notifyNewChat,
                      activeColor: AppColors.primary,
                      onChanged: (v) { setState(() => _notifyNewChat = v); setDlgState(() {}); _saveAdminSettings(); },
                    ),
                    SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('새 주문 알림', style: TextStyle(fontSize: 13)),
                      value: _notifyNewOrder,
                      activeColor: AppColors.primary,
                      onChanged: (v) { setState(() => _notifyNewOrder = v); setDlgState(() {}); _saveAdminSettings(); },
                    ),
                    SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('문자(SMS) 알림 연동', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('관리자 전화번호로 문의/주문 알림 발송', style: TextStyle(fontSize: 11)),
                      value: _notifyChatSms,
                      activeColor: AppColors.primary,
                      onChanged: (v) { setState(() => _notifyChatSms = v); setDlgState(() {}); _saveAdminSettings(); },
                    ),
                    const SizedBox(height: 8),
                    // 전화번호 입력
                    TextField(
                      decoration: InputDecoration(
                        labelText: '관리자 연락처 (알림 수신)',
                        hintText: '010-0000-0000',
                        prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      controller: TextEditingController(text: _adminPhone),
                      onChanged: (v) { _adminPhone = v; _saveAdminSettings(); },
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    // 안내 박스
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD600)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF57F17)),
                            SizedBox(width: 4),
                            Text('알림 안내', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF57F17))),
                          ]),
                          SizedBox(height: 6),
                          Text('• 브라우저 알림 허용 시 새 문의/주문 즉시 알림', style: TextStyle(fontSize: 11, color: Color(0xFF5D4037))),
                          Text('• 채팅 문의 시 관리자 화면에 실시간 반영', style: TextStyle(fontSize: 11, color: Color(0xFF5D4037))),
                          Text('• 외부 SMS/카카오 연동은 서버 API 설정 필요', style: TextStyle(fontSize: 11, color: Color(0xFF5D4037))),
                          Text('• 카카오채널: @2fitkorea', style: TextStyle(fontSize: 11, color: Color(0xFF5D4037))),
                          SizedBox(height: 4),
                          SelectableText(
                            '카카오 비즈니스: bizmessage.kakao.com',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
              ElevatedButton(
                onPressed: () {
                  _saveAdminSettings();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림 설정이 저장되었습니다'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  Widget _notifItem(IconData icon, String msg, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
        Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
      ]),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return const Color(0xFFFF8F00);
      case OrderStatus.confirmed:
        return const Color(0xFF1565C0);
      case OrderStatus.processing:
        return const Color(0xFF6A1B9A);
      case OrderStatus.shipped:
        return const Color(0xFF00838F);
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return const Color(0xFFE53935);
      case OrderStatus.refunded:
        return const Color(0xFF888888);
    }
  }

  String _today() {
    final now = DateTime.now();
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${now.year}년 ${now.month}월 ${now.day}일 (${days[now.weekday - 1]})';
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _fmtPrice(double p) => p
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  // ══════════════════════════════════════════════
  // TAB 7 : 채팅 상담 관리 (Firestore 실시간)
  // ══════════════════════════════════════════════
  // ignore: unused_field
  int _selectedChatIdx = -1; // -1 = 목록 보기
  String? _selectedRoomId;   // 선택된 채팅방 ID

  Widget _buildChatManagement() {
    final width = MediaQuery.of(context).size.width;
    final isPc = kIsWeb && width >= 900;

    // PC: 좌측 목록 + 우측 상세 2단 레이아웃
    if (isPc) {
      return Row(
        children: [
          // ── 좌측: 채팅방 목록 (280px 고정)
          SizedBox(
            width: 300,
            child: _buildChatRoomList(),
          ),
          Container(width: 1, color: const Color(0xFFEEEEEE)),
          // ── 우측: 채팅 상세 or 빈 화면
          Expanded(
            child: _selectedRoomId != null
                ? _buildFirestoreChatDetail(_selectedRoomId!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Color(0xFFBBBBBB)),
                        SizedBox(height: 16),
                        Text('채팅방을 선택하세요', style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
                        SizedBox(height: 8),
                        Text('좌측 목록에서 고객을 클릭하면\n대화 내용을 확인할 수 있습니다',
                            style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
          ),
        ],
      );
    }

    // 모바일: 기존 방식 (목록 → 클릭 → 상세)
    if (_selectedRoomId != null) {
      return _buildFirestoreChatDetail(_selectedRoomId!);
    }
    return _buildChatRoomList();
  }

  // 채팅방 목록 위젯 (PC/모바일 공통)
  Widget _buildChatRoomList() {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(child: Text('채팅 상담 목록', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              StreamBuilder<List<ChatRoomModel>>(
                stream: ChatService.watchAllRooms(),
                builder: (_, snap) {
                  final unread = (snap.data ?? []).fold(0, (s, r) => s + r.unreadCount);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread건 미답', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                  );
                },
              ),
            ],
          ),
        ),
        // 알림 배너
        if (_notifyNewChat)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, size: 14, color: Color(0xFF1565C0)),
                const SizedBox(width: 6),
                const Expanded(child: Text('실시간 채팅 알림 활성화됨', style: TextStyle(fontSize: 11, color: Color(0xFF1565C0)))),
                if (_adminPhone.isNotEmpty)
                  Text('📱 $_adminPhone', style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
              ],
            ),
          ),
        // Firestore 실시간 채팅방 목록
        Expanded(
          child: StreamBuilder<List<ChatRoomModel>>(
            stream: ChatService.watchAllRooms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rooms = snapshot.data ?? [];
              if (rooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('아직 채팅 문의가 없습니다', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, i) {
                  final room = rooms[i];
                  final diff = DateTime.now().difference(room.lastTime);
                  final timeStr = diff.inMinutes < 60 ? '${diff.inMinutes}분 전' : diff.inHours < 24 ? '${diff.inHours}시간 전' : '${diff.inDays}일 전';
                  final isSelected = room.id == _selectedRoomId;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedRoomId = room.id);
                      ChatService.markAsRead(room.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              room.userName.characters.first,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.userName,
                                        style: TextStyle(fontSize: 14, fontWeight: room.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  room.lastMessage.isEmpty ? '새 채팅이 시작됐습니다' : room.lastMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: room.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (room.unreadCount > 0)
                            Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                              child: Center(child: Text('${room.unreadCount}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
                            )
                          else
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Firestore 실시간 채팅 상세 화면 (관리자)
  Widget _buildFirestoreChatDetail(String roomId) {
    final replyCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    void scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    void sendAdminReply() {
      final text = replyCtrl.text.trim();
      if (text.isEmpty) return;
      ChatService.adminReply(roomId: roomId, text: text);
      replyCtrl.clear();
      scrollToBottom();
    }

    return StatefulBuilder(
      builder: (context, setDetailState) {
        return Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  // PC에서는 뒤로가기 버튼 숨김
                  if (!(kIsWeb && MediaQuery.of(context).size.width >= 900))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                      onPressed: () => setState(() => _selectedRoomId = null),
                      color: AppColors.textPrimary,
                    ),
                  StreamBuilder<List<ChatRoomModel>>(
                    stream: ChatService.watchAllRooms(),
                    builder: (_, snap) {
                      final room = (snap.data ?? []).where((r) => r.id == roomId).firstOrNull;
                      return Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                (room?.userName ?? '?').characters.first,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(room?.userName ?? '고객', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                  Text(room?.language == 'ko' ? '한국어 채팅' : '다국어 채팅', style: const TextStyle(fontSize: 10, color: Color(0xFFFF8F00))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                    ),
                    child: const Text('상담 중', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // 실시간 메시지
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: ChatService.watchMessages(roomId),
                builder: (context, snapshot) {
                  final msgs = snapshot.data ?? [];
                  // 새 메시지 도착 시 자동 스크롤
                  if (msgs.isNotEmpty) scrollToBottom();
                  if (msgs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 8),
                          Text('아직 메시지가 없습니다', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final timeStr =
                          '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}';
                      return Align(
                        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                              decoration: BoxDecoration(
                                color: m.isUser ? AppColors.primary : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: m.isUser ? const Radius.circular(14) : const Radius.circular(4),
                                  bottomRight: m.isUser ? const Radius.circular(4) : const Radius.circular(14),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!m.isUser)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(m.senderName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                                    ),
                                  Text(m.text, style: TextStyle(fontSize: 13, color: m.isUser ? Colors.white : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                              child: Text(timeStr, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // 빠른 답변 템플릿
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFFF5F5F5),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  '안녕하세요! 2FIT 고객센터입니다 😊',
                  '확인 후 빠르게 연락드리겠습니다.',
                  '단체주문은 최소 5인 이상입니다.',
                  '제작기간은 약 2~3주 소요됩니다.',
                  '추가 문의사항이 있으시면 말씀해 주세요!',
                ].map((tpl) => GestureDetector(
                  onTap: () {
                    replyCtrl.text = tpl;
                    replyCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: tpl.length),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6, top: 5, bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: Center(
                      child: Text(
                        tpl.length > 16 ? '${tpl.substring(0, 16)}…' : tpl,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            // 답장 입력 (Enter 전송 지원)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      decoration: InputDecoration(
                        hintText: '답장 입력... (Enter로 전송)',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.primary)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        filled: true, fillColor: const Color(0xFFF8F9FA), isDense: true,
                      ),
                      minLines: 1, maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => sendAdminReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: sendAdminReply,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildChatEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('채팅 세션을 선택하세요', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildChatDetail(Map<String, dynamic> session) {
    final messages = session['messages'] as List<ChatMessage>;
    final replyCtrl = TextEditingController();

    return StatefulBuilder(
      builder: (context, setDetailState) {
        return Column(
          children: [
            // 상단 헤더 (뒤로가기 포함)
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: () => setState(() => _selectedChatIdx = -1),
                    color: AppColors.textPrimary,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (session['user'] as String).characters.first,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session['user'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                        const Text('한국어로 표시 중', style: TextStyle(fontSize: 10, color: Color(0xFFFF8F00))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                    ),
                    child: const Text('상담 중', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // 메시지 영역
            Expanded(child: AdminChatView(messages: messages)),
            // 답장 입력
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      decoration: InputDecoration(
                        hintText: '답장 입력...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.primary)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (replyCtrl.text.trim().isEmpty) return;
                      setDetailState(() {
                        (session['messages'] as List<ChatMessage>).add(
                          ChatMessage(text: replyCtrl.text.trim(), isUser: false, time: DateTime.now()),
                        );
                        session['lastMsg'] = replyCtrl.text.trim();
                        replyCtrl.clear();
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  // TAB 6 : 섹션 관리
  // ══════════════════════════════════════════════
  Widget _buildSectionManagement() {
    final products = context.watch<ProductProvider>().adminProducts;
    final selectedProduct = _sectionSelectedProductId != null && products.isNotEmpty
        ? products.firstWhere(
            (p) => p.id == _sectionSelectedProductId,
            orElse: () => products.first,
          )
        : null;

    return Column(
      children: [
        // ── 상품 선택 헤더 ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.layers_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('섹션 이미지 관리', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text('상품별 상세페이지 섹션 이미지를 관리합니다', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                  // 섹션 추가 버튼
                  ElevatedButton.icon(
                    onPressed: () => _showAddSectionDialog(),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('섹션 추가', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 상품 선택 드롭다운
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sectionSelectedProductId,
                    hint: const Text('상품을 선택하세요', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF555555)),
                    items: products.map((p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              p.images.isNotEmpty ? p.images.first : '',
                              width: 32, height: 32, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 32, height: 32, color: const Color(0xFFEEEEEE),
                                child: const Icon(Icons.checkroom_rounded, size: 16, color: Color(0xFFCCCCCC)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                Text('${p.category} · ID: ${p.id}', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                              ],
                            ),
                          ),
                          if (p.sectionImages.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${p.sectionImages.values.fold(0, (s, v) => s + v.length)}장',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) => setState(() => _sectionSelectedProductId = val),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 섹션 카드 목록 ──
        if (selectedProduct == null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.layers_rounded, size: 40, color: Color(0xFFBBBBBB)),
                  ),
                  const SizedBox(height: 16),
                  const Text('위에서 상품을 선택하면\n섹션별 이미지를 관리할 수 있습니다',
                      style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6), textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: _customSections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 48, color: Color(0xFFBBBBBB)),
                        const SizedBox(height: 12),
                        const Text('섹션이 없습니다', style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSectionDialog(),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('첫 섹션 추가하기'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _customSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final sec = _customSections[i];
                      final key = sec['key'] as String;
                      final imgs = selectedProduct.sectionImages[key] ?? [];
                      return Stack(
                        children: [
                          _AdminSectionCard(
                            sectionKey: key,
                            sectionLabel: sec['label'] as String,
                            sectionTitle: sec['title'] as String,
                            sectionDescription: (sec['description'] as String?) ?? '',
                            icon: sec['icon'] as IconData,
                            images: imgs,
                            product: selectedProduct,
                            onUpdated: () => setState(() {}),
                          ),
                          // 삭제 버튼 (우상단)
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () => _confirmDeleteSection(i),
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
      ],
    );
  }

  // 섹션 추가 다이얼로그
  void _showAddSectionDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    Uint8List? pickedImageBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('섹션 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 섹션 이름 ──
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: '섹션 이름 *',
                    hintText: '예: 착용 이미지, 색상 안내...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                // ── 섹션 설명 ──
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '섹션 설명 (선택)',
                    hintText: '이 섹션에 대한 간단한 설명을 입력하세요',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                // ── 대표 이미지 업로드 ──
                const Text('대표 이미지 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200, maxHeight: 1200);
                    if (file == null) return;
                    final bytes = await file.readAsBytes();
                    setDialogState(() => pickedImageBytes = bytes);
                  },
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
                    ),
                    child: pickedImageBytes != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.memory(pickedImageBytes!, width: double.infinity, height: 130, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 6, right: 6,
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => pickedImageBytes = null),
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFFBBBBBB)),
                              SizedBox(height: 6),
                              Text('탭하여 이미지 선택', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final newKey = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                final desc  = descCtrl.text.trim();

                String? imageUrl;
                if (pickedImageBytes != null) {
                  setDialogState(() => isUploading = true);
                  imageUrl = await StorageService.uploadBannerImage(
                    bannerId: 'section_thumb_$newKey',
                    imageBytes: pickedImageBytes!,
                  );
                }

                setState(() {
                  _customSections.add({
                    'key': newKey,
                    'label': '섹션 ${_customSections.length + 1}',
                    'title': title,
                    'description': desc,
                    'icon': Icons.image_rounded,
                    if (imageUrl != null) 'thumbUrl': imageUrl,
                  });
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('섹션 "$title" 이 추가되었습니다'), backgroundColor: const Color(0xFF1A1A2E)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
              child: isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  // 섹션 삭제 확인
  void _confirmDeleteSection(int index) {
    final sec = _customSections[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('섹션 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('"${sec['title']}" 섹션을 삭제하시겠습니까?\n이미지 데이터는 유지됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              setState(() => _customSections.removeAt(index));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${sec['title']}" 섹션이 삭제되었습니다'), backgroundColor: const Color(0xFFE53935)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 7 : 색상 관리
  // ══════════════════════════════════════════════
  Widget _buildColorManagement() {
    final filtered = _colorCategoryFilter == '전체'
        ? _colorItems
        : _colorItems.where((c) => c['category'] == _colorCategoryFilter).toList();
    final allSelected = filtered.isNotEmpty &&
        filtered.every((c) => _selectedColorIds.contains(c['id'] as String));
    final anySelected = _selectedColorIds.isNotEmpty;

    return Column(
      children: [
        // ── 헤더 툴바 ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.palette_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('색상 관리', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text('상품 색상을 추가/편집/삭제합니다', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddColorDialog(),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('색상 추가', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 카테고리 필터
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colorCategories.map((cat) {
                    final isSelected = _colorCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _colorCategoryFilter = cat;
                          _selectedColorIds.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : const Color(0xFF555555),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // ── 전체선택 / 삭제 바 ──
        if (anySelected)
          Container(
            color: const Color(0xFFFFF3E0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('${_selectedColorIds.length}개 선택됨', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _colorItems.removeWhere((c) => _selectedColorIds.contains(c['id'] as String));
                      _selectedColorIds.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('선택된 색상이 삭제되었습니다'), backgroundColor: Color(0xFFE53935)),
                    );
                  },
                  icon: const Icon(Icons.delete_rounded, size: 16, color: Color(0xFFE53935)),
                  label: const Text('삭제', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedColorIds.clear()),
                  child: const Text('취소', style: TextStyle(color: Color(0xFF888888))),
                ),
              ],
            ),
          ),
        // ── 색상 그리드 ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.palette_outlined, size: 60, color: Color(0xFFDDDDDD)),
                      const SizedBox(height: 16),
                      const Text('색상이 없습니다', style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddColorDialog(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('색상 추가'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 전체선택 행
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Checkbox(
                              value: allSelected,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedColorIds.addAll(filtered.map((c) => c['id'] as String));
                                } else {
                                  _selectedColorIds.removeAll(filtered.map((c) => c['id'] as String));
                                }
                              }),
                              activeColor: const Color(0xFF1A1A2E),
                            ),
                            const Text('전체 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${filtered.length}개', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          ],
                        ),
                      ),
                      // 색상 카드 그리드
                      LayoutBuilder(builder: (ctx, constraints) {
                        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            final id = c['id'] as String;
                            final isSelected = _selectedColorIds.contains(id);
                            final hexColor = _parseHex(c['hexCode'] as String);
                            final hasImage = c['hasImage'] as bool;
                            final buttonCard = c['buttonCard'] as bool;
                            final active = c['active'] as bool;

                            return GestureDetector(
                              onTap: () => _showEditColorDialog(c),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 색상 미리보기 영역
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                          child: hasImage && (c['imageUrl'] as String).isNotEmpty
                                              ? Image.network(
                                                  c['imageUrl'] as String,
                                                  height: 90,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    height: 90, width: double.infinity,
                                                    color: hexColor,
                                                  ),
                                                )
                                              : Container(
                                                  height: 90,
                                                  width: double.infinity,
                                                  color: hexColor,
                                                  child: hexColor.computeLuminance() > 0.5
                                                    ? Icon(Icons.circle, size: 30, color: Colors.black.withValues(alpha: 0.1))
                                                    : Icon(Icons.circle, size: 30, color: Colors.white.withValues(alpha: 0.1)),
                                                ),
                                        ),
                                        // 체크박스
                                        Positioned(
                                          top: 6, left: 6,
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              if (isSelected) {
                                                _selectedColorIds.remove(id);
                                              } else {
                                                _selectedColorIds.add(id);
                                              }
                                            }),
                                            child: Container(
                                              width: 20, height: 20,
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF1A1A2E) : Colors.white.withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: isSelected ? const Color(0xFF1A1A2E) : Colors.grey.withValues(alpha: 0.5)),
                                              ),
                                              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                            ),
                                          ),
                                        ),
                                        // 활성화 뱃지
                                        Positioned(
                                          top: 6, right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: active ? const Color(0xFF43A047) : const Color(0xFF9E9E9E),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(active ? '활성' : '비활성', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // 색상 정보
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 14, height: 14,
                                                  decoration: BoxDecoration(
                                                    color: hexColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: const Color(0xFFDDDDDD)),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    c['name'] as String,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(c['hexCode'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                                            const SizedBox(height: 2),
                                            Text(c['category'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
                                            const Spacer(),
                                            // 아이콘 형태 배지들
                                            Row(
                                              children: [
                                                if (hasImage)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(4)),
                                                    child: const Text('이미지', style: TextStyle(fontSize: 9, color: Color(0xFF1565C0))),
                                                  ),
                                                if (hasImage) const SizedBox(width: 3),
                                                if (buttonCard)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                                                    child: const Text('카드', style: TextStyle(fontSize: 9, color: Color(0xFF2E7D32))),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // 편집/삭제 버튼
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _showEditColorDialog(c),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF0F0F0),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.edit_rounded, size: 11, color: Color(0xFF555555)),
                                                    SizedBox(width: 3),
                                                    Text('편집', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('색상 삭제'),
                                                  content: Text('"${c['name']}" 색상을 삭제하시겠습니까?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
                                                      onPressed: () {
                                                        setState(() => _colorItems.removeWhere((item) => item['id'] == id));
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('"${c['name']}" 색상이 삭제되었습니다'), backgroundColor: const Color(0xFFE53935)),
                                                        );
                                                      },
                                                      child: const Text('삭제'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEBEE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.delete_rounded, size: 11, color: Color(0xFFE53935)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _showAddColorDialog() {
    final nameCtrl = TextEditingController();
    final hexCtrl = TextEditingController(text: '#');
    String category = '기본색';
    bool hasImage = false;
    bool buttonCard = true;
    bool active = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('색상 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('색상 이름', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: '예: 딥네이비, 버건디...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('HEX 코드', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: hexCtrl,
                  decoration: InputDecoration(
                    hintText: '#1A1A2E',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('카테고리', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: ['기본색', '포인트색', '시즌색'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setS(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('이미지 연결', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Switch(
                            value: hasImage,
                            onChanged: (v) => setS(() => hasImage = v),
                            activeThumbColor: const Color(0xFF1A1A2E),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('버튼카드 생성', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Switch(
                            value: buttonCard,
                            onChanged: (v) => setS(() => buttonCard = v),
                            activeThumbColor: const Color(0xFF1A1A2E),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('활성화', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Switch(
                            value: active,
                            onChanged: (v) => setS(() => active = v),
                            activeThumbColor: const Color(0xFF43A047),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 색상 미리보기
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('미리보기: ', style: TextStyle(fontSize: 12)),
                    Container(
                      width: 40, height: 24,
                      decoration: BoxDecoration(
                        color: _parseHex(hexCtrl.text),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final hex = hexCtrl.text.trim();
                if (name.isEmpty || hex.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('색상 이름과 HEX 코드를 입력해주세요'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final newId = 'c_${DateTime.now().millisecondsSinceEpoch}';
                setState(() {
                  _colorItems.add({
                    'id': newId,
                    'name': name,
                    'hexCode': hex.startsWith('#') ? hex : '#$hex',
                    'category': category,
                    'hasImage': hasImage,
                    'imageUrl': '',
                    'buttonCard': buttonCard,
                    'active': active,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$name" 색상이 추가되었습니다. ${buttonCard ? '버튼카드도 자동 생성됩니다.' : ''}'), backgroundColor: const Color(0xFF1A1A2E)),
                );
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditColorDialog(Map<String, dynamic> colorData) {
    final nameCtrl = TextEditingController(text: colorData['name'] as String);
    final hexCtrl = TextEditingController(text: colorData['hexCode'] as String);
    String category = colorData['category'] as String;
    bool hasImage = colorData['hasImage'] as bool;
    bool buttonCard = colorData['buttonCard'] as bool;
    bool active = colorData['active'] as bool;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _parseHex(colorData['hexCode'] as String),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
              ),
              const SizedBox(width: 8),
              Text('${colorData['name']} 편집', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('색상 이름', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('HEX 코드', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: hexCtrl,
                  onChanged: (_) => setS(() {}),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _parseHex(hexCtrl.text),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('카테고리', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: ['기본색', '포인트색', '시즌색'].contains(category) ? category : '기본색',
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: ['기본색', '포인트색', '시즌색'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setS(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                const Text('설정', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _switchTile('이미지 연결', hasImage, (v) => setS(() => hasImage = v)),
                    ),
                    Expanded(
                      child: _switchTile('버튼카드', buttonCard, (v) => setS(() => buttonCard = v)),
                    ),
                    Expanded(
                      child: _switchTile('활성화', active, (v) => setS(() => active = v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
              onPressed: () {
                final idx = _colorItems.indexWhere((c) => c['id'] == colorData['id']);
                if (idx >= 0) {
                  setState(() {
                    _colorItems[idx] = {
                      ..._colorItems[idx],
                      'name': nameCtrl.text.trim(),
                      'hexCode': hexCtrl.text.trim().startsWith('#') ? hexCtrl.text.trim() : '#${hexCtrl.text.trim()}',
                      'category': category,
                      'hasImage': hasImage,
                      'buttonCard': buttonCard,
                      'active': active,
                    };
                  });
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('색상이 수정되었습니다'), backgroundColor: Color(0xFF1A1A2E)),
                );
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFF1A1A2E)),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // TAB 8 : 디자인 수정 요청 관리
  // ══════════════════════════════════════════════
  Widget _buildDesignRequests() {
    final filtered = _designRequestFilter == '전체'
        ? _designRequests
        : _designRequests.where((r) => r['status'] == _designRequestFilter).toList();
    final allSelected = filtered.isNotEmpty &&
        filtered.every((r) => _selectedDesignRequestIds.contains(r['id'] as String));
    final anySelected = _selectedDesignRequestIds.isNotEmpty;

    return Column(
      children: [
        // ── 헤더 ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF6A1B9A), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.design_services_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('디자인 수정 요청', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text('고객의 디자인 수정 요청을 관리합니다', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                  // 새로고침 버튼
                  IconButton(
                    onPressed: _loadDesignRequests,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: '새로고침',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E5F5),
                      foregroundColor: const Color(0xFF6A1B9A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      fixedSize: const Size(34, 34),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 요청 건수 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '총 ${_designRequests.length}건',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 상태 필터 칩들
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _designRequestStatuses.map((status) {
                    final isSelected = _designRequestFilter == status;
                    final count = status == '전체'
                        ? _designRequests.length
                        : _designRequests.where((r) => r['status'] == status).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _designRequestFilter = status;
                          _selectedDesignRequestIds.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? _getDesignStatusColor(status) : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : const Color(0xFF555555),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$count', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : const Color(0xFF666666))),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // ── 전체선택/삭제 바 ──
        if (anySelected)
          Container(
            color: const Color(0xFFF3E5F5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('${_selectedDesignRequestIds.length}개 선택됨',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A))),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _designRequests.removeWhere((r) => _selectedDesignRequestIds.contains(r['id'] as String));
                      _selectedDesignRequestIds.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('선택된 요청이 삭제되었습니다'), backgroundColor: Color(0xFFE53935)),
                    );
                  },
                  icon: const Icon(Icons.delete_rounded, size: 16, color: Color(0xFFE53935)),
                  label: const Text('삭제', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDesignRequestIds.clear()),
                  child: const Text('취소', style: TextStyle(color: Color(0xFF888888))),
                ),
              ],
            ),
          ),
        // ── 목록 ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.design_services_outlined, size: 60, color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _designRequestFilter == '전체' ? '디자인 수정 요청이 없습니다' : '"$_designRequestFilter" 상태의 요청이 없습니다',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      // 전체선택 행
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: allSelected,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedDesignRequestIds.addAll(filtered.map((r) => r['id'] as String));
                                } else {
                                  _selectedDesignRequestIds.removeAll(filtered.map((r) => r['id'] as String));
                                }
                              }),
                              activeColor: const Color(0xFF6A1B9A),
                            ),
                            const Text('전체 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${filtered.length}건', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          ],
                        ),
                      );
                    }
                    final req = filtered[i - 1];
                    final id = req['id'] as String;
                    final isSelected = _selectedDesignRequestIds.contains(id);
                    final status = req['status'] as String;
                    final createdAt = req['createdAt'] as DateTime;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6A1B9A) : const Color(0xFFEEEEEE),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          // 헤더 행
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _selectedDesignRequestIds.add(id);
                                    } else {
                                      _selectedDesignRequestIds.remove(id);
                                    }
                                  }),
                                  activeColor: const Color(0xFF6A1B9A),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _getDesignStatusColor(status).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _getDesignStatusColor(status).withValues(alpha: 0.3)),
                                            ),
                                            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getDesignStatusColor(status))),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(req['requestType'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 13, color: Color(0xFF888888)),
                                          const SizedBox(width: 4),
                                          Text(req['userName'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.receipt_rounded, size: 13, color: Color(0xFF888888)),
                                          const SizedBox(width: 4),
                                          Text(req['orderId'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        req['description'] as String,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFAAAAAA)),
                                          const SizedBox(width: 3),
                                          Text(
                                            _formatDesignDate(createdAt),
                                            style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 관리자 메모
                          if ((req['adminNote'] as String).isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_rounded, size: 12, color: Color(0xFF6A1B9A)),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(req['adminNote'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF4A148C)))),
                                ],
                              ),
                            ),
                          // 액션 버튼들
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Row(
                              children: [
                                if (status == '대기중')
                                  Expanded(child: _drActionBtn('처리 시작', const Color(0xFF1565C0), () => _updateDesignRequestStatus(req, '처리중'))),
                                if (status == '처리중') ...[
                                  Expanded(child: _drActionBtn('완료 처리', const Color(0xFF2E7D32), () => _updateDesignRequestStatus(req, '완료'))),
                                  const SizedBox(width: 6),
                                  Expanded(child: _drActionBtn('거절', const Color(0xFFE53935), () => _updateDesignRequestStatus(req, '거절'))),
                                ],
                                if (status == '완료' || status == '거절')
                                  Expanded(child: _drActionBtn('재처리', const Color(0xFF6A1B9A), () => _updateDesignRequestStatus(req, '처리중'))),
                                const SizedBox(width: 6),
                                Expanded(child: _drActionBtn('메모 추가', const Color(0xFF555555), () => _showAddAdminNoteDialog(req))),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _designRequests.removeWhere((r) => r['id'] == id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('요청이 삭제되었습니다'), backgroundColor: Color(0xFFE53935)),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.delete_rounded, size: 14, color: Color(0xFFE53935)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _drActionBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ),
  );

  Color _getDesignStatusColor(String status) {
    switch (status) {
      case '대기중': return const Color(0xFFE65100);
      case '처리중': return const Color(0xFF1565C0);
      case '완료': return const Color(0xFF2E7D32);
      case '거절': return const Color(0xFFE53935);
      default: return const Color(0xFF555555);
    }
  }

  String _formatDesignDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  void _updateDesignRequestStatus(Map<String, dynamic> req, String newStatus) {
    final idx = _designRequests.indexWhere((r) => r['id'] == req['id']);
    if (idx >= 0) {
      setState(() => _designRequests[idx] = {..._designRequests[idx], 'status': newStatus});
      // 완료/거절 시 Firestore에서 colorEditRequested 플래그 해제
      if (newStatus == '완료' || newStatus == '거절') {
        final orderId = req['orderId'] as String? ?? req['id'] as String;
        FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'colorEditRequested': false,
          'colorEditHandledAt': FieldValue.serverTimestamp(),
          'colorEditHandledStatus': newStatus,
        }).catchError((e) {
          if (kDebugMode) debugPrint('디자인 수정 처리 업데이트 실패: $e');
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태가 "$newStatus"로 변경되었습니다'), backgroundColor: _getDesignStatusColor(newStatus)),
      );
    }
  }

  void _showAddAdminNoteDialog(Map<String, dynamic> req) {
    final noteCtrl = TextEditingController(text: req['adminNote'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('관리자 메모', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '처리 내용, 메모 등을 입력하세요...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A), foregroundColor: Colors.white),
            onPressed: () {
              final idx = _designRequests.indexWhere((r) => r['id'] == req['id']);
              if (idx >= 0) setState(() => _designRequests[idx] = {..._designRequests[idx], 'adminNote': noteCtrl.text.trim()});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메모가 저장되었습니다'), backgroundColor: Color(0xFF6A1B9A)),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 관리자 섹션 카드 위젯
// ══════════════════════════════════════════════════════════════
class _AdminSectionCard extends StatefulWidget {
  final String sectionKey;
  final String sectionLabel;
  final String sectionTitle;
  final String sectionDescription;
  final IconData icon;
  final List<String> images;
  final ProductModel product;
  final VoidCallback onUpdated;

  const _AdminSectionCard({
    required this.sectionKey,
    required this.sectionLabel,
    required this.sectionTitle,
    this.sectionDescription = '',
    required this.icon,
    required this.images,
    required this.product,
    required this.onUpdated,
  });

  @override
  State<_AdminSectionCard> createState() => _AdminSectionCardState();
}

class _AdminSectionCardState extends State<_AdminSectionCard> {
  bool _expanded = false;
  bool _isUploading = false;
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  List<String> get _imgs =>
      ProductService.getAllProductsSync()
          .firstWhere((p) => p.id == widget.product.id,
              orElse: () => widget.product)
          .sectionImages[widget.sectionKey] ?? [];

  void _refresh() {
    widget.onUpdated();
    setState(() {});
  }

  // 이미지 파일 선택 & Firebase Storage 업로드
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    setState(() => _isUploading = true);
    try {
      final files = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1200, maxHeight: 1200);
      if (files.isEmpty) { setState(() => _isUploading = false); return; }

      final current = List<String>.from(_imgs);
      for (int i = 0; i < files.length; i++) {
        final bytes = await files[i].readAsBytes();
        // Firebase Storage에 업로드
        final url = await StorageService.uploadSectionImage(
          productId: widget.product.id,
          sectionKey: widget.sectionKey,
          bytes: bytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        current.add(url);
      }
      await context.read<ProductProvider>().updateSectionImages(widget.product.id, widget.sectionKey, current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.sectionLabel} 이미지 ${files.length}장 업로드 완료'),
          backgroundColor: const Color(0xFF1A1A2E),
        ));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('업로드 실패: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  // URL로 이미지 추가
  Future<void> _addByUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final current = List<String>.from(_imgs)..add(url);
    await context.read<ProductProvider>().updateSectionImages(widget.product.id, widget.sectionKey, current);
    _urlCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.sectionLabel} URL 이미지 추가 완료'),
        backgroundColor: const Color(0xFF1A1A2E),
      ));
      _refresh();
    }
  }

  // 이미지 삭제
  Future<void> _deleteImage(int index) async {
    final current = List<String>.from(_imgs)..removeAt(index);
    await context.read<ProductProvider>().updateSectionImages(widget.product.id, widget.sectionKey, current);
    _refresh();
  }

  // 전체 삭제
  void _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${widget.sectionLabel} 이미지 전체 삭제'),
        content: const Text('이 섹션의 모든 이미지를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await context.read<ProductProvider>().updateSectionImages(widget.product.id, widget.sectionKey, []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.sectionLabel} 이미지 전체 삭제 완료'),
          backgroundColor: Colors.orange,
        ));
        _refresh();
      }
    }
  }

  // 순서 변경 (위로)
  Future<void> _moveUp(int index) async {
    if (index == 0) return;
    final current = List<String>.from(_imgs);
    final tmp = current[index];
    current[index] = current[index - 1];
    current[index - 1] = tmp;
    await context.read<ProductProvider>().updateSectionImages(widget.product.id, widget.sectionKey, current);
    _refresh();
  }

  // 순서 변경 (아래로)
  Future<void> _moveDown(int index) async {
    final imgs = _imgs;
    if (index >= imgs.length - 1) return;
    final current = List<String>.from(imgs);
    final tmp = current[index];
    current[index] = current[index + 1];
    current[index + 1] = tmp;
    await context.read<ProductProvider>().updateSectionImages(widget.product.id, widget.sectionKey, current);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = _imgs;
    final hasImages = imgs.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        children: [
          // ── 카드 헤더 (탭하면 펼치기/닫기) ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _expanded ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(14))
                    : BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // 섹션 아이콘
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon,
                        color: _expanded ? Colors.white : const Color(0xFF1A1A2E),
                        size: 20),
                  ),
                  const SizedBox(width: 12),
                  // 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.sectionLabel} · ${widget.sectionTitle}',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _expanded ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        if (widget.sectionDescription.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            widget.sectionDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: _expanded
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          hasImages ? '이미지 ${imgs.length}장 등록됨' : '이미지 없음 (기본 UI 표시)',
                          style: TextStyle(
                            fontSize: 11,
                            color: _expanded
                                ? Colors.white.withValues(alpha: 0.65)
                                : hasImages ? const Color(0xFF2E7D32) : const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 이미지 개수 배지
                  if (hasImages)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _expanded
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${imgs.length}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _expanded ? Colors.white70 : const Color(0xFF888888),
                  ),
                ],
              ),
            ),
          ),

          // ── 펼쳐진 내용 ──
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 이미지 추가 버튼들 ──
                  Row(
                    children: [
                      // 파일 업로드
                      Expanded(
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickImages,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isUploading)
                                  const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                else
                                  const Icon(Icons.upload_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(_isUploading ? '업로드 중...' : '이미지 추가',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 전체 삭제
                      if (hasImages)
                        GestureDetector(
                          onTap: _deleteAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.delete_sweep_rounded, color: Color(0xFFE53935), size: 16),
                                SizedBox(width: 5),
                                Text('전체삭제',
                                    style: TextStyle(
                                        color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── URL 입력으로 추가 ──
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlCtrl,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: '이미지 URL 직접 입력',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => _addByUrl(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addByUrl,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('추가',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),

                  // ── 등록된 이미지 목록 ──
                  if (hasImages) ...[
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.photo_library_rounded, size: 14, color: Color(0xFF555555)),
                        SizedBox(width: 5),
                        Text('등록된 이미지',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...imgs.asMap().entries.map((e) {
                      final idx = e.key;
                      final url = e.value;
                      final isBase64 = url.startsWith('data:image');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            // 이미지 썸네일
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              child: isBase64
                                  ? Image.memory(
                                      base64Decode(url.split(',').last),
                                      width: 70, height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      url,
                                      width: 70, height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 70, height: 70,
                                        color: const Color(0xFFEEEEEE),
                                        child: const Icon(Icons.broken_image_outlined,
                                            size: 28, color: Color(0xFFCCCCCC)),
                                      ),
                                    ),
                            ),
                            // 이미지 정보
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '이미지 ${idx + 1}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isBase64
                                          ? '[로컬 업로드 이미지]'
                                          : url.length > 40 ? '${url.substring(0, 40)}...' : url,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 순서 및 삭제 버튼
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 위로
                                IconButton(
                                  onPressed: idx > 0 ? () => _moveUp(idx) : null,
                                  icon: Icon(Icons.keyboard_arrow_up_rounded,
                                      color: idx > 0 ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
                                      size: 20),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                                // 아래로
                                IconButton(
                                  onPressed: idx < imgs.length - 1 ? () => _moveDown(idx) : null,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: idx < imgs.length - 1 ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
                                      size: 20),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            // 삭제
                            IconButton(
                              onPressed: () => _deleteImage(idx),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFE53935), size: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFDDDDDD), style: BorderStyle.solid),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.image_outlined, size: 32, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 6),
                          Text('등록된 이미지가 없습니다\n기본 UI가 표시됩니다',
                              style: TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.5),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 상품 추가/수정 다이얼로그 (카테고리+하위카테고리 + 다중 이미지 업로드)
// ══════════════════════════════════════════════════════════════
class _ProductFormDialog extends StatefulWidget {
  final ProductModel? existing;
  final Future<void> Function(ProductModel, bool isEdit) onSaved;

  const _ProductFormDialog({required this.onSaved, this.existing});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  // ── 텍스트 컨트롤러
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _origPriceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _sizesCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _urlCtrl;

  // ── 자동번역 상태
  Map<String, String> _nameTranslations = {};
  Map<String, String> _descTranslations = {};
  bool _isTranslating = false;
  String _lastTranslatedName = '';

  // 상품명 입력 후 1.2초 뒤 자동번역 (디바운스)
  DateTime? _lastTyped;
  void _onNameChanged(String val) {
    _lastTyped = DateTime.now();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final now = DateTime.now();
      if (_lastTyped != null && now.difference(_lastTyped!).inMilliseconds >= 1200) {
        final name = val.trim();
        if (name.isNotEmpty && name != _lastTranslatedName) {
          _triggerTranslation(name);
        }
      }
    });
  }

  Future<void> _triggerTranslation(String name) async {
    if (!mounted) return;
    setState(() => _isTranslating = true);
    final result = await TranslationService.translateWithCache(name);
    if (!mounted) return;
    setState(() {
      _nameTranslations = result;
      _lastTranslatedName = name;
      _isTranslating = false;
    });
  }

  // ── 카테고리
  String _selCat = '상의';
  String _selSubCat = '';
  String _selTightsSub = ''; // 타이즈 하위분류 (9부/5부/4부/3부/2.5부/숏쇼츠)

  // ── 선택된 색상 (twoFitColors 기반)
  final Set<String> _selectedColors = {};

  // ── 이미지 (base64 or url 혼합)
  List<String> _images = [];
  bool _isUploading = false;
  String _uploadStatus = '';
  String _uploadError = '';
  bool _isSaving = false;
  // ── 토글
  bool _isNew = false;
  bool _isSale = false;
  bool _isFreeShip = false;
  bool _isGroupOnly = false;
  bool _isActive = true;

  bool get _isEdit => widget.existing != null;

  // ── 카테고리별 하위카테고리 맵
  static const Map<String, List<String>> _subCatMap = {
    '상의': [
      '싱글렛 A타입', '싱글렛 B타입', '크롭탑', '라운드티', '카라티',
      '롱 슬리브', '맨투맨', '후드집업', '트레이닝 집업',
    ],
    '하의': ['타이즈', '트레이닝바지', '반바지'],
    '세트': ['싱글렛세트A타입', '트레이닝복세트'],
    '아우터': ['바람막이', '다운패딩', '다운조끼패딩', '롱패딩'],
    '스킨슈트': ['스킨슈트'],
    '악세사리': ['모자', '백팩'],
    '이벤트': ['이벤트'],
  };

  // 타이즈 하위분류 (하의 > 타이즈 선택 시 추가 선택)
  static const List<String> _tightsSubCats = [
    '9부', '5부', '4부', '3부', '2.5부', '숏쇼츠',
  ];

  static const List<String> _mainCategories = [
    '상의', '하의', '세트', '아우터', '스킨슈트', '악세사리', '이벤트',
  ];

  List<String> get _currentSubCats => _subCatMap[_selCat] ?? [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _origPriceCtrl = TextEditingController(text: e?.originalPrice?.toStringAsFixed(0) ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _sizesCtrl = TextEditingController(text: (e?.sizes ?? ['S','M','L','XL']).join(', '));
    _stockCtrl = TextEditingController(text: e?.stockCount.toString() ?? '100');
    _urlCtrl = TextEditingController();

    // 기존 번역 로드
    if (e != null && e.nameTranslations.isNotEmpty) {
      _nameTranslations = Map<String, String>.from(e.nameTranslations);
      _lastTranslatedName = e.name;
    }
    if (e != null && e.descriptionTranslations.isNotEmpty) {
      _descTranslations = Map<String, String>.from(e.descriptionTranslations);
    }

    _selCat = e?.category ?? '상의';
    _selSubCat = e?.subCategory ?? '';
    _images = List<String>.from(e?.images ?? []);
    _isNew = e?.isNew ?? false;
    _isSale = e?.isSale ?? false;
    _isFreeShip = e?.isFreeShipping ?? false;
    _isGroupOnly = e?.isGroupOnly ?? false;
    _isActive = e?.isActive ?? true;

    // 기존 상품의 색상 복원
    if (e != null) {
      _selectedColors.addAll(e.colors);
    } else {
      _selectedColors.addAll(['블랙', '화이트']); // 기본값 K=블랙, PP=화이트
    }

    // 하위카테고리 초기값 보정
    final subs = _currentSubCats;
    if (_selSubCat.isEmpty || !subs.contains(_selSubCat)) {
      _selSubCat = subs.isNotEmpty ? subs.first : '';
    }
    // 타이즈 하위분류 복원
    if (_selCat == '하의' && _selSubCat == '타이즈') {
      // subCategory 마지막 부분에 길이 정보가 있을 수 있음
      _selTightsSub = '9부'; // 기본값
    }

    // 신규등록 시 카테고리 기본설명 세팅
    if (e == null) {
      _descCtrl.text = _defaultDescForCat(_selCat);
    }
  }

  // ── 카테고리별 기본 설명 자동생성
  String _defaultDescForCat(String cat) {
    switch (cat) {
      case '상의':
        return '2FIT의 고품질 스포츠 상의입니다.\n78% Nylon, 22% Spandex / 4-way Stretch 소재로 뛰어난 신축성과 내구성을 제공합니다.\n심리스(무봉제) 설계로 피부 마찰을 최소화하며 편안한 착용감을 드립니다.\n빠른 건조와 땀 흡수 기능으로 운동 중 쾌적함을 유지합니다.';
      case '하의':
        return '2FIT 스포츠 하의입니다.\n78% Nylon, 22% Spandex / 4-way Stretch 소재로 최고의 신축성 제공.\n허리밴드는 와이드 설계로 흘러내림 없이 고정됩니다.\n운동 중 움직임을 방해하지 않는 인체공학적 패턴 적용.';
      case '세트':
        return '2FIT 상·하의 세트 상품입니다.\n동일 소재·컬러로 코디 고민 없이 완성되는 올인원 세트.\n78% Nylon, 22% Spandex / 4-way Stretch로 편안하고 활동적인 착용감.\n다양한 스포츠 및 일상 활동에 모두 적합합니다.';
      case '아우터':
        return '2FIT 스포츠 아우터입니다.\n뛰어난 보온성과 방풍 기능으로 실외 운동 시 최적의 퍼포먼스를 발휘합니다.\n가볍고 콤팩트하게 수납 가능하며 다양한 활동에 어울리는 디자인.\n앞뒤 주머니 및 지퍼 포켓 구성.';
      case '스킨슈트':
        return '2FIT 스킨슈트입니다.\n78% Nylon, 22% Spandex / 4-way Stretch 소재로 전신을 감싸는 완벽한 핏.\n심리스 설계로 솔기 없이 부드러운 착용감을 제공합니다.\n크로스핏, 사이클링, 트라이애슬론에 최적화된 원피스 디자인.';
      case '악세사리':
        return '2FIT 스포츠 악세사리입니다.\n운동 효과를 극대화하고 편의성을 높여주는 고품질 아이템.\n내구성 있는 소재 사용으로 오랜 사용에도 변형 없음.\n다양한 운동 환경에 맞게 설계된 기능성 제품.';
      case '이벤트':
        return '2FIT 이벤트 특가 상품입니다.\n한정 수량으로 준비된 특별 혜택 상품.\n빠른 주문 마감 예정이오니 서두르세요!';
      default:
        return '2FIT의 프리미엄 스포츠 웨어입니다.\n78% Nylon, 22% Spandex / 4-way Stretch 소재 사용.\n고강도 운동부터 일상 착용까지 모든 상황에 적합합니다.';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _origPriceCtrl.dispose();
    _descCtrl.dispose(); _sizesCtrl.dispose();
    _stockCtrl.dispose(); _urlCtrl.dispose();
    super.dispose();
  }

  // ── 이미지 파일 여러 장 선택 & Firebase Storage 업로드
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    setState(() { _isUploading = true; _uploadError = ''; _uploadStatus = '파일 선택 중...'; });
    try {
      final files = await picker.pickMultiImage();
      if (!mounted) return;
      if (files.isEmpty) {
        setState(() { _isUploading = false; _uploadStatus = ''; });
        return;
      }

      // ① 즉시 base64 미리보기 추가 (업로드 전에 바로 화면에 표시)
      final previews = <String>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        previews.add(b64);
      }
      if (!mounted) return;
      setState(() {
        _images = [..._images, ...previews];
        _uploadStatus = 'Firebase 업로드 중... (0/${files.length})';
      });

      // ② 백그라운드에서 Firebase Storage 업로드 후 URL 교체
      final productId = widget.existing?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
      int success = 0;
      for (int i = 0; i < files.length; i++) {
        if (!mounted) break;
        setState(() => _uploadStatus = 'Firebase 업로드 중... (${i + 1}/${files.length})');
        try {
          final bytes = await files[i].readAsBytes();
          final url = await StorageService.uploadProductImage(
            productId: productId,
            bytes: bytes,
            fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          if (url.isNotEmpty && mounted) {
            // base64 미리보기를 실제 URL로 교체
            final previewIdx = _images.indexOf(previews[i]);
            if (previewIdx >= 0) {
              setState(() => _images[previewIdx] = url);
            }
            success++;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('이미지 업로드 실패 ($i): $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
        _uploadError = success == 0
            ? '업로드 실패: Firebase Storage를 확인하세요.\n미리보기는 로컬 이미지로 표시됩니다.'
            : '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
        _uploadError = '오류: $e';
      });
    }
  }

  // ── URL로 이미지 추가
  void _addImageByUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _images.add(url); });
    _urlCtrl.clear();
  }

  // ── 이미지 삭제
  void _removeImage(int i) => setState(() => _images.removeAt(i));

  // ── 이미지 순서 위로
  void _moveUp(int i) {
    if (i == 0) return;
    setState(() {
      final tmp = _images[i]; _images[i] = _images[i-1]; _images[i-1] = tmp;
    });
  }

  // ── 저장
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상품명을 입력해주세요')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('올바른 가격을 입력해주세요')));
      return;
    }
    final origPrice = double.tryParse(_origPriceCtrl.text.replaceAll(',', ''));
    final images = List<String>.from(_images);
    if (images.isEmpty) images.add('https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/400');

    // 번역이 아직 안 됐으면 저장 전 실행
    final productName = _nameCtrl.text.trim();
    final productDesc = _descCtrl.text.trim();
    Map<String, String> translations = _nameTranslations;
    Map<String, String> descTranslations = _descTranslations;
    if (translations.isEmpty || _lastTranslatedName != productName) {
      if (mounted) setState(() => _isTranslating = true);
      translations = await TranslationService.translateWithCache(productName);
      if (mounted) setState(() { _nameTranslations = translations; _isTranslating = false; });
    }
    // 설명 번역 (번역 없으면 실행)
    if (descTranslations.isEmpty && productDesc.isNotEmpty) {
      descTranslations = await TranslationService.translateLongText(productDesc);
      if (mounted) setState(() => _descTranslations = descTranslations);
    }

    final product = ProductModel(
      id: widget.existing?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: productName,
      category: _selCat,
      // 타이즈인 경우 서브카테고리에 길이 포함 (예: "타이즈 9부")
      subCategory: _selSubCat == '타이즈' && _selTightsSub.isNotEmpty
          ? '타이즈 $_selTightsSub'
          : _selSubCat,
      price: price,
      originalPrice: (origPrice != null && origPrice > price) ? origPrice : null,
      description: _descCtrl.text.trim(),
      images: images,
      sizes: _sizesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      colors: _selectedColors.toList(),
      isNew: _isNew, isSale: _isSale, isFreeShipping: _isFreeShip, isGroupOnly: _isGroupOnly,
      stockCount: int.tryParse(_stockCtrl.text) ?? 100,
      isActive: _isActive,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      nameTranslations: translations,
      descriptionTranslations: descTranslations,
    );
    if (mounted) setState(() => _isSaving = true);
    try {
      await widget.onSaved(product, _isEdit);
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(_isEdit ? '${product.name} 수정 완료!' : '${product.name} 등록 완료!'),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ));
      // 수정 모드면 폼 유지, 신규 등록이면 닫기
      if (!_isEdit) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('저장 실패: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 540,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Icon(_isEdit ? Icons.edit_outlined : Icons.add_box_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_isEdit ? '상품 수정' : '새 상품 등록',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // ── 폼 스크롤
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── 상품명 + 자동번역
                _lbl('상품명 * (한국어 입력 → 자동번역)'),
                TextField(
                  controller: _nameCtrl,
                  onChanged: _onNameChanged,
                  decoration: InputDecoration(
                    hintText: '상품명 입력',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                    suffixIcon: _isTranslating
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A2E))))
                        : _nameTranslations.isNotEmpty
                            ? const Icon(Icons.translate, color: Color(0xFF4CAF50), size: 20)
                            : null,
                  ),
                ),
                // 번역 미리보기
                if (_nameTranslations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌐 자동번역 미리보기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                        const SizedBox(height: 4),
                        if (_nameTranslations['en'] != null)
                          _translationRow('🇺🇸 EN', _nameTranslations['en']!),
                        if (_nameTranslations['ja'] != null)
                          _translationRow('🇯🇵 JA', _nameTranslations['ja']!),
                        if (_nameTranslations['zh'] != null)
                          _translationRow('🇨🇳 ZH', _nameTranslations['zh']!),
                        if (_nameTranslations['mn'] != null)
                          _translationRow('🇲🇳 MN', _nameTranslations['mn']!),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // ── 카테고리 + 하위카테고리
                _lbl('카테고리'),
                Row(children: [
                  // 메인 카테고리
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selCat,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          borderRadius: BorderRadius.circular(10),
                          items: _mainCategories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selCat = v;
                              final subs = _subCatMap[v] ?? [];
                              _selSubCat = subs.isNotEmpty ? subs.first : '';
                              _selTightsSub = '';
                              // 신규 등록 시 카테고리별 설명 자동입력
                              if (!_isEdit) {
                                _descCtrl.text = _defaultDescForCat(v);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 하위 카테고리
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3F51B5).withValues(alpha: 0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentSubCats.contains(_selSubCat) ? _selSubCat : (_currentSubCats.isNotEmpty ? _currentSubCats.first : null),
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          borderRadius: BorderRadius.circular(10),
                          items: _currentSubCats
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                              _selSubCat = v;
                              if (v != '타이즈') {
                                _selTightsSub = '';
                              } else {
                                _selTightsSub = '9부';
                              }
                            });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ]),
                // 타이즈 하위분류 (하의 > 타이즈 선택 시에만 표시)
                if (_selCat == '하의' && _selSubCat == '타이즈') ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const SizedBox(width: 2),
                    Icon(Icons.straighten, size: 13, color: Colors.purple[400]),
                    const SizedBox(width: 4),
                    Text('타이즈 하위분류', style: TextStyle(fontSize: 12, color: Colors.purple[600], fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tightsSubCats.map((s) {
                      final sel = _selTightsSub == s;
                      return GestureDetector(
                        onTap: () => setState(() => _selTightsSub = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF6A1B9A) : const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? const Color(0xFF6A1B9A) : const Color(0xFFCE93D8)),
                          ),
                          child: Text(s, style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? Colors.white : const Color(0xFF6A1B9A),
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  const SizedBox(width: 2),
                  Icon(Icons.info_outline, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('카테고리 → 하위카테고리 순서로 선택', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ]),
                const SizedBox(height: 14),

                // ── 가격
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _lbl('판매가 (원) *'),
                    _field(_priceCtrl, '0', type: TextInputType.number),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _lbl('정가 (원, 선택)'),
                    _field(_origPriceCtrl, '0', type: TextInputType.number),
                  ])),
                ]),
                const SizedBox(height: 14),

                // ── 재고
                _lbl('재고 수량'),
                _field(_stockCtrl, '100', type: TextInputType.number),
                const SizedBox(height: 14),

                // ── 상품 설명
                _lbl('상품 설명'),
                TextField(
                  controller: _descCtrl, maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '상품 설명 입력',
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 14),

                // ══════════════════════════════
                // ── 이미지 업로드 섹션
                // ══════════════════════════════
                Row(children: [
                  const Text('상품 이미지', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_images.length}장', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),

                // 업로드 버튼 + URL 입력
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickImages,
                      icon: _isUploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(_isUploading
                          ? (_uploadStatus.isNotEmpty ? _uploadStatus : '처리 중...')
                          : '이미지 파일 선택'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
                // 업로드 에러 메시지
                if (_uploadError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_uploadError,
                                  style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.5)),
                              const SizedBox(height: 6),
                              const Text('👇 아래 URL 직접 입력을 사용해 주세요',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _uploadError = ''),
                          child: const Icon(Icons.close, size: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // URL 입력 행
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      decoration: InputDecoration(
                        hintText: 'URL로 이미지 추가 (https://...)',
                        hintStyle: const TextStyle(fontSize: 12),
                        filled: true, fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addImageByUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('추가', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 10),

                // 이미지 미리보기 그리드
                if (_images.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: List.generate(_images.length, (i) {
                        final img = _images[i];
                        final isBase64 = img.startsWith('data:');
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: i == 0 ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0), width: i == 0 ? 2 : 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: isBase64
                                    ? Image.memory(base64Decode(img.split(',').last), fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32, color: Colors.grey))
                                    : Image.network(img, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32, color: Colors.grey)),
                              ),
                            ),
                            // 대표 배지
                            if (i == 0)
                              Positioned(
                                bottom: 4, left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A2E),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('대표', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            // 삭제 버튼
                            Positioned(
                              top: -6, right: -6,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                            // 위로 버튼 (대표 이미지 아닐 때)
                            if (i > 0)
                              Positioned(
                                top: -6, left: -6,
                                child: GestureDetector(
                                  onTap: () => _moveUp(i),
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700], shape: BoxShape.circle),
                                    child: const Icon(Icons.arrow_upward, size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '첫 번째 이미지가 대표 이미지입니다. ↑ 버튼으로 순서 변경',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(children: [
                      Icon(Icons.image_outlined, size: 36, color: Colors.grey[400]),
                      const SizedBox(height: 6),
                      Text('이미지를 추가해주세요', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),

                // ── 사이즈
                _lbl('사이즈 (쉼표 구분)'),
                _field(_sizesCtrl, 'S, M, L, XL'),
                const SizedBox(height: 14),

                // ── 색상 선택 (twoFitColors 체크박스 그리드)
                Row(children: [
                  _lbl('기성품 색상 선택'),
                  const SizedBox(width: 8),
                  if (_selectedColors.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_selectedColors.length}개 선택',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ]),
                // K/PP 안내 배지
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 13, color: Color(0xFFE65100)),
                    SizedBox(width: 6),
                    Expanded(child: Text(
                      'K(블랙) · PP(화이트) → 기본가  |  그 외 색상 → +₩20,000',
                      style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AppConstants.twoFitColors.map((c) {
                      final name = c['name'] as String;
                      final hexVal = c['hex'] as int;
                      final isSelected = _selectedColors.contains(name);
                      final isFree = name == '블랙' || name == '화이트';
                      final isLight = hexVal == 0xFFF5F5F5 || hexVal == 0xFFFFFBEA ||
                          hexVal == 0xFFF8BBD0 || hexVal == 0xFFE6CCFF || hexVal == 0xFFFFCBA4 ||
                          hexVal == 0xFFF5E6C8 || hexVal == 0xFFFFFFFF || hexVal == 0xFFFFFF00;
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedColors.remove(name);
                          } else {
                            _selectedColors.add(name);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(hexVal),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isLight ? const Color(0xFF333333) : Colors.white)
                                  : const Color(0xFFCCCCCC),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              if (isSelected)
                                Icon(Icons.check_rounded,
                                    size: 12,
                                    color: isLight ? const Color(0xFF333333) : Colors.white),
                              if (isSelected) const SizedBox(width: 3),
                              Text(name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isLight ? const Color(0xFF333333) : Colors.white,
                                  )),
                            ]),
                            if (!isFree)
                              Text('+2만원',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: (isLight ? const Color(0xFF333333) : Colors.white).withValues(alpha: 0.8),
                                ),
                              ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 토글 칩
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip('신상품', _isNew, (v) => setState(() => _isNew = v)),
                  _chip('세일', _isSale, (v) => setState(() => _isSale = v)),
                  _chip('무료배송', _isFreeShip, (v) => setState(() => _isFreeShip = v)),
                  _chip('단체전용', _isGroupOnly, (v) => setState(() => _isGroupOnly = v), ac: const Color(0xFF6A1B9A)),
                  _chip('활성화', _isActive, (v) => setState(() => _isActive = v), ac: Colors.green),
                ]),
                const SizedBox(height: 8),
              ]),
            ),
          ),

          // ── 하단 버튼
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('취소'),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? '수정 저장' : '상품 등록',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── 헬퍼 위젯
  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
  );

  Widget _translationRow(String flag, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Text(flag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)))),
    ]),
  );

  Widget _field(TextEditingController c, String hint, {TextInputType type = TextInputType.text}) =>
    TextField(
      controller: c, keyboardType: type,
      decoration: InputDecoration(
        hintText: hint, filled: true, fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );

  Widget _chip(String label, bool val, ValueChanged<bool> onChanged, {Color? ac}) =>
    FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: val ? Colors.white : const Color(0xFF555555))),
      selected: val,
      onSelected: onChanged,
      selectedColor: ac ?? const Color(0xFF1A1A2E),
      backgroundColor: const Color(0xFFF0F0F0),
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
} // end _ProductFormDialogState


// ════════════════════════════════════════════════════════
//  공지사항 관리 탭 (StatefulWidget)
// ════════════════════════════════════════════════════════
class _NoticeManagementTab extends StatefulWidget {
  const _NoticeManagementTab();
  @override
  State<_NoticeManagementTab> createState() => _NoticeManagementTabState();
}

class _NoticeManagementTabState extends State<_NoticeManagementTab> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<NoticeProvider>().loadAllForAdmin();
    if (mounted) setState(() => _loaded = true);
  }

  // ── 등록/수정 다이얼로그 ──
  Future<void> _openEditor({NoticeModel? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.titleKo ?? '');
    final contentCtrl = TextEditingController(text: existing?.contentKo ?? '');
    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A148C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.campaign_rounded, color: Color(0xFF4A148C), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? '공지사항 등록' : '공지사항 수정',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('제목 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: '공지사항 제목을 입력하세요',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('내용 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: '공지사항 내용을 입력하세요\n\n이모지 사용 가능 (예: ✅ 📦 🎉)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('즉시 활성화', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF4A148C),
                        onChanged: (v) => setD(() => isActive = v),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.translate_rounded, size: 14, color: Color(0xFF795548)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '저장 후 자동으로 5개 언어로 번역됩니다 (영·일·중·몽)',
                            style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Color(0xFF888888))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A148C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();
                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
                  );
                  return;
                }
                // 수정 시 제목/내용이 변경되면 번역 초기화 (재번역 유도)
                final titleChanged = existing != null && existing.titleKo != title;
                final contentChanged = existing != null && existing.contentKo != content;
                final notice = NoticeModel(
                  id: existing?.id ?? 'notice_${DateTime.now().millisecondsSinceEpoch}',
                  titleKo: title,
                  contentKo: content,
                  titleTranslations: titleChanged ? const {} : (existing?.titleTranslations ?? const {}),
                  contentTranslations: contentChanged ? const {} : (existing?.contentTranslations ?? const {}),
                  isActive: isActive,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                // provider 참조를 팝업 닫기 전에 미리 가져옴
                final noticeProvider = context.read<NoticeProvider>();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final isEdit = existing != null;
                Navigator.pop(ctx);
                try {
                  await noticeProvider.saveNotice(notice);
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Row(children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(isEdit ? '공지사항이 수정되었습니다' : '공지사항이 등록되었습니다'),
                        ]),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(existing == null ? '등록' : '저장'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 삭제 확인 ──
  Future<void> _confirmDelete(NoticeModel notice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 22),
            SizedBox(width: 8),
            Text('공지사항 삭제', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          '\'${notice.titleKo}\'\n공지사항을 삭제하시겠습니까?\n삭제 후 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<NoticeProvider>().deleteNotice(notice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.delete_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('공지사항이 삭제되었습니다'),
            ]),
            backgroundColor: const Color(0xFF616161),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoticeProvider>();
    final notices = provider.allNotices;
    final isLoading = provider.isLoading;

    return Container(
      color: const Color(0xFFF0F2F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A148C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFF4A148C), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('공지사항 관리',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                    Text('총 ${notices.length}개 · 활성 ${notices.where((n) => n.isActive).length}개',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('새 공지 등록', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A148C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          // ── 안내 배너 ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF5C6BC0).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF3949AB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '활성 공지는 앱 홈화면 팝업으로 표시됩니다. 한국어로 등록하면 자동으로 5개 언어(영·일·중·몽)로 번역됩니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF3949AB), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 목록 ──
          Expanded(
            child: isLoading && !_loaded
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A148C)))
                : notices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A148C).withValues(alpha: 0.07),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF4A148C)),
                            ),
                            const SizedBox(height: 16),
                            const Text('등록된 공지사항이 없습니다',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                            const SizedBox(height: 8),
                            const Text('\'새 공지 등록\' 버튼을 눌러 첫 번째 공지를 작성해보세요',
                                style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: notices.length,
                        itemBuilder: (ctx, i) {
                          final n = notices[i];
                          return _NoticeCard(
                            notice: n,
                            onEdit: () => _openEditor(existing: n),
                            onDelete: () => _confirmDelete(n),
                            onToggleActive: () => context.read<NoticeProvider>().toggleNoticeActive(n.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── 개별 공지카드 ──
class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _NoticeCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = notice.isActive;
    final dateStr = '${notice.createdAt.year}.${notice.createdAt.month.toString().padLeft(2,'0')}.${notice.createdAt.day.toString().padLeft(2,'0')}';
    final hasTranslations = notice.titleTranslations.containsKey('en');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFF4A148C).withValues(alpha: 0.2) : const Color(0xFFEEEEEE),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 카드 헤더 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4A148C).withValues(alpha: 0.05)
                  : const Color(0xFFF8F8F8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                // 활성 상태 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF4A148C) : const Color(0xFFBBBBBB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? '● 활성' : '○ 비활성',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                // 번역 상태
                if (hasTranslations)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.translate_rounded, size: 10, color: Color(0xFF1565C0)),
                        SizedBox(width: 3),
                        Text('번역완료', style: TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ),
          // ── 제목 + 내용 미리보기 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.titleKo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  notice.contentKo,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ── 액션 버튼 ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                // 활성/비활성 토글
                OutlinedButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 14,
                  ),
                  label: Text(
                    isActive ? '비활성화' : '활성화',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? const Color(0xFF888888) : const Color(0xFF2E7D32),
                    side: BorderSide(
                      color: isActive ? const Color(0xFFCCCCCC) : const Color(0xFF2E7D32),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                // 수정
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('수정', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(color: Color(0xFF1565C0)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),
                // 삭제
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFFE53935),
                  tooltip: '삭제',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
