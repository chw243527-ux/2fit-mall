import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart';
import '../../services/email_service.dart';

class ChatMessage {
  final String text;
  final String originalText; // 원문 (번역 전 텍스트)
  final bool isUser;
  final DateTime time;
  final bool isSystem;
  bool showOriginal; // 원문 보기 토글

  ChatMessage({
    required this.text,
    String? originalText,
    required this.isUser,
    required this.time,
    this.isSystem = false,
    this.showOriginal = false,
  }) : originalText = originalText ?? text;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  // ignore: unused_field
  final bool _showFaq = true;
  bool _faqExpanded = true;

  // ── Firestore 실시간 채팅
  String? _roomId;
  // ignore: unused_field
  bool _isLoadingRoom = true;

  AppLocalizations get _loc =>
      context.watch<LanguageProvider>().loc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFirestoreChat();
    });
  }

  // Firestore 채팅방 초기화 및 실시간 메시지 수신
  Future<void> _initFirestoreChat() async {
    final user = context.read<UserProvider>().user;
    final userId = user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final userName = user?.name ?? _loc.chatVisitor;
    final lang = _loc.language.code;

    try {
      final roomId = await ChatService.getOrCreateRoom(
        userId: userId,
        userName: userName,
        language: lang,
      );
      if (!mounted) return;
      setState(() {
        _roomId = roomId;
        _isLoadingRoom = false;
      });

      // 실시간 메시지 스트림 구독
      ChatService.watchMessages(roomId).listen((firestoreMsgs) {
        if (!mounted) return;
        setState(() {
          _messages.clear();
          // Firestore 메시지가 없으면 환영 메시지 표시
          if (firestoreMsgs.isEmpty) {
            _initializeChat();
            return;
          }
          for (final m in firestoreMsgs) {
            _messages.add(ChatMessage(
              text: m.text,
              originalText: m.originalText,
              isUser: m.isUser,
              time: m.time,
              isSystem: m.isSystem,
            ));
          }
        });
        _scrollToBottom();
      });
    } catch (e) {
      // Firestore 연결 실패 시 로컬 모드로 폴백
      if (!mounted) return;
      setState(() => _isLoadingRoom = false);
      _initializeChat();
    }
  }

  void _initializeChat() {
    final loc = _loc;
    final now = DateTime.now();
    setState(() {
      _messages.addAll([
        ChatMessage(
          text: loc.chatWelcome,
          isUser: false,
          time: now.subtract(const Duration(minutes: 2)),
        ),
        ChatMessage(
          text: loc.chatWelcome2,
          isUser: false,
          time: now.subtract(const Duration(minutes: 2)),
        ),
      ]);
    });
  }

  /// FAQ 키 -> 답변 맵 (현재 언어 기준)
  List<Map<String, String>> _getFaqItems(AppLocalizations loc) {
    return [
      {'q': loc.faqOrderStatus,     'a': loc.faqOrderStatusAns,   'icon': '📦'},
      {'q': loc.faqShipping,        'a': loc.faqShippingAns,      'icon': '🚚'},
      {'q': loc.faqSize,            'a': loc.faqSizeAns,          'icon': '📏'},
      {'q': loc.faqCustomOrder,     'a': loc.faqCustomOrderAns,   'icon': '🎨'},
      {'q': loc.faqReturn,          'a': loc.faqReturnAns,        'icon': '🔄'},
      {'q': loc.faqGroupOrder,      'a': loc.faqGroupOrderAns,    'icon': '👥'},
      {'q': loc.faqEliteAthlete,    'a': '',                      'icon': '🏆'},
    ];
  }

  void _sendFaqMessage(String questionText, String answerText, AppLocalizations loc) {
    if (questionText == loc.faqEliteAthlete) {
      _showEliteDialog(loc);
      return;
    }

    final isKorean = loc.language == AppLanguage.korean;
    String koreanQuestion = _toKoreanFaqQuestion(questionText, loc);
    final user = context.read<UserProvider>().user;
    final userId = user?.id ?? 'guest';
    final userName = user?.name ?? _loc.chatVisitor;
    final displayQuestion = isKorean ? questionText : koreanQuestion;

    if (_roomId != null) {
      // Firestore 전송 + 자동답변
      ChatService.sendMessage(
        roomId: _roomId!,
        text: displayQuestion,
        originalText: questionText,
        senderId: userId,
        senderName: userName,
        isUser: true,
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || _roomId == null) return;
        ChatService.adminReply(roomId: _roomId!, text: answerText);
      });
    } else {
      // 폴백: 로컬 즉시 표시
      setState(() {
        _messages.add(ChatMessage(
          text: displayQuestion,
          originalText: questionText,
          isUser: true,
          time: DateTime.now(),
        ));
        _isTyping = true;
      });
      _scrollToBottom();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: answerText,
            isUser: false,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      });
    }

    AdminNotificationStore.addChatNotification(
      userName: userName,
      message: isKorean ? questionText : '$questionText ($koreanQuestion)',
      language: loc.language.code,
    );

    // 관리자 이메일 알림 (FAQ 문의도 알림)
    EmailService.sendChatAlert(
      userName: userName,
      message: displayQuestion,
      userId: userId,
    );
  }

  void _sendMessage(String text, AppLocalizations loc) {
    if (text.trim().isEmpty) return;

    final isKorean = loc.language == AppLanguage.korean;
    final user = context.read<UserProvider>().user;
    final userId = user?.id ?? 'guest';
    final userName = user?.name ?? _loc.chatVisitor;

    _messageController.clear();

    // Firestore 전송
    if (_roomId != null) {
      ChatService.sendMessage(
        roomId: _roomId!,
        text: text.trim(),
        senderId: userId,
        senderName: userName,
        isUser: true,
      );
      // 자동접수 안내 (첫 메시지에만 1회 발송)
      if (_messages.where((m) => m.isUser).length <= 1) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_roomId == null || !mounted) return;
          final autoReply = '${loc.chatAutoReplyMsg}${AppConstants.customerServicePhone}';
          ChatService.adminReply(roomId: _roomId!, text: autoReply);
        });
      }
    } else {
      // 폴백: 로컬 모드
      setState(() {
        _messages.add(ChatMessage(
          text: text.trim(),
          originalText: text.trim(),
          isUser: true,
          time: DateTime.now(),
        ));
        _isTyping = true;
      });
      _scrollToBottom();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final defaultReply = '${loc.chatWelcome2}\n\n'
            '${loc.chatOfflineMsg}\n'
            '${AppConstants.customerServicePhone}';
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: defaultReply, isUser: false, time: DateTime.now()));
        });
        _scrollToBottom();
      });
    }

    AdminNotificationStore.addChatNotification(
      userName: userName,
      message: text.trim(),
      language: loc.language.code,
    );

    // 관리자 이메일 알림 발송 (핸드폰으로 수신)
    EmailService.sendChatAlert(
      userName: userName,
      message: text.trim(),
      userId: userId,
    );
  }

  /// FAQ 질문을 한국어로 변환 (관리자용)
  String _toKoreanFaqQuestion(String localizedQ, AppLocalizations loc) {
    final items = _getFaqItems(const AppLocalizations(AppLanguage.korean));
    final localizedItems = _getFaqItems(loc);
    for (int i = 0; i < localizedItems.length; i++) {
      if (localizedItems[i]['q'] == localizedQ && i < items.length) {
        return items[i]['q'] ?? localizedQ;
      }
    }
    return localizedQ;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEliteDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(loc.chatEliteTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, size: 40, color: Color(0xFFFF6F00)),
                  const SizedBox(height: 8),
                  const Text(
                    AppConstants.eliteAthletePhone,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFF6F00)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.chatEliteDesc,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.chatWeekdayHours,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.close),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
            label: Text(loc.chatCallNow, style: const TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.chatPhoneInquiry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_rounded, size: 48, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              AppConstants.customerServicePhone,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              loc.chatWeekdayHours,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.close),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.chatCallNow),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final width = MediaQuery.of(context).size.width;
    final isPc = kIsWeb && width >= 900;

    return Consumer<LanguageProvider>(
      builder: (_, lp, __) {
        final loc = lp.loc;
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: loc.back,
            ),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.chatTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(loc.chatOnline, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                onPressed: () => _showCallDialog(loc),
                tooltip: loc.chatPhoneInquiry,
              ),
            ],
          ),
          body: isPc
              // ── PC: 좌측 FAQ 사이드바 + 우측 채팅창
              ? Row(
                  children: [
                    // 좌측 FAQ 사이드바 (320px)
                    Container(
                      width: 320,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(right: BorderSide(color: AppColors.border)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0xFF1A1A2E),
                            child: Row(
                              children: [
                                const Icon(Icons.quiz_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(loc.chatQuickTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(12),
                              children: _getFaqItems(loc).map((faq) {
                                return InkWell(
                                  onTap: () => faq['a']!.isNotEmpty
                                      ? _sendFaqMessage(faq['q']!, faq['a']!, loc)
                                      : _showEliteDialog(loc),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFEEEEEE)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(faq['icon']!, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(faq['q']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFBBBBBB)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // 전화 문의 버튼
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                            child: OutlinedButton.icon(
                              onPressed: () => _showCallDialog(loc),
                              icon: const Icon(Icons.phone_rounded, size: 16),
                              label: Text(loc.chatPhoneInquiry),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 우측 채팅창
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _messages.isEmpty
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _messages.length) return _buildTypingIndicator();
                                      return _buildMessageBubble(_messages[index], loc);
                                    },
                                  ),
                          ),
                          _buildInputArea(loc),
                        ],
                      ),
                    ),
                  ],
                )
              // ── 모바일: 기존 레이아웃
              : Column(
                  children: [
                    _buildFaqPanel(loc),
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length) return _buildTypingIndicator();
                                return _buildMessageBubble(_messages[index], loc);
                              },
                            ),
                    ),
                    _buildInputArea(loc),
                  ],
                ),
        );
      },
    );
  }

  // ────────── FAQ 패널 (항상 표시) ──────────
  Widget _buildFaqPanel(AppLocalizations loc) {
    final faqs = _getFaqItems(loc);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // 헤더 (접기/펼치기)
          InkWell(
            onTap: () => setState(() => _faqExpanded = !_faqExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    loc.chatQuickTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  const Spacer(),
                  Icon(
                    _faqExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // FAQ 버튼들
          if (_faqExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: faqs.map((faq) {
                  final isElite = faq['q'] == loc.faqEliteAthlete;
                  return GestureDetector(
                    onTap: () => _sendFaqMessage(faq['q']!, faq['a']!, loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isElite ? const Color(0xFFFFF3E0) : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isElite ? const Color(0xFFFF9800) : const Color(0xFF7986CB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(faq['icon']!, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            faq['q']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isElite ? const Color(0xFFE65100) : const Color(0xFF3949AB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ────────── 메시지 버블 ──────────
  Widget _buildMessageBubble(ChatMessage message, AppLocalizations loc) {
    final isKorean = loc.language == AppLanguage.korean;
    // 관리자용 번역 표시 여부
    final hasTranslation = message.isUser &&
        !isKorean &&
        message.text != message.originalText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: message.isUser ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                          bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                        ),
                        border: message.isUser ? null : Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        // 원문 보기가 켜져 있으면 원문, 아니면 현재 표시 텍스트
                        message.showOriginal ? message.originalText : message.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.isUser ? Colors.white : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                        ),
                        // 번역된 메시지의 경우 원문 보기 버튼
                        if (hasTranslation) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => message.showOriginal = !message.showOriginal),
                            child: Text(
                              message.showOriginal ? loc.chatShowOriginal : loc.chatTranslatedLabel,
                              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (message.isUser) const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  // ────────── 타이핑 인디케이터 ──────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(200),
                const SizedBox(width: 4),
                _buildDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (_, value, __) {
        return Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: AppColors.textHint.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // ────────── 입력창 ──────────
  Widget _buildInputArea(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: loc.chatInputHint,
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
              ),
              minLines: 1,
              maxLines: 4,
              onSubmitted: (t) => _sendMessage(t, loc),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: () => _sendMessage(_messageController.text, loc),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AdminChatView: 관리자가 고객 메시지를 한국어로 보는 뷰
// ─────────────────────────────────────────────────────────────────
class AdminChatView extends StatelessWidget {
  final List<ChatMessage> messages;
  const AdminChatView({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        // 관리자는 항상 한국어 원문 우선 표시
        final displayText = msg.isUser ? msg.originalText : msg.text;
        return _AdminMsgTile(message: msg, displayText: displayText);
      },
    );
  }
}

class _AdminMsgTile extends StatelessWidget {
  final ChatMessage message;
  final String displayText;

  const _AdminMsgTile({required this.message, required this.displayText});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(right: 6, top: 2),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.support_agent_rounded, size: 14, color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isUser && message.originalText != message.text) ...[
                    Row(children: [
                      const Icon(Icons.translate_rounded, size: 12, color: Color(0xFF1565C0)),
                      const SizedBox(width: 4),
                      Text(loc.chatOriginalLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      displayText,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc.chatOriginalText}${message.text}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ] else
                    Text(
                      displayText,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.time.hour.toString().padLeft(2, '0')}:'
                    '${message.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
