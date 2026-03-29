// chat_service.dart - Firestore 기반 채팅 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatServiceMessage {
  final String id;
  final String senderId;
  final String senderName;
  // chat_screen 호환 필드
  final String text;
  final String originalText;
  final bool isUser;
  final bool isAdmin;
  final DateTime time;
  final bool isSystem;
  final bool isRead;

  ChatServiceMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    String? originalText,
    required this.isUser,
    this.isAdmin = false,
    required this.time,
    this.isSystem = false,
    this.isRead = false,
  }) : originalText = originalText ?? text;

  String get message => text;
  DateTime get createdAt => time;

  factory ChatServiceMessage.fromMap(String id, Map<String, dynamic> data) {
    final isAdm = data['isAdmin'] as bool? ?? false;
    final msg = data['message'] as String? ?? data['text'] as String? ?? '';
    return ChatServiceMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '회원',
      text: msg,
      originalText: data['originalText'] as String? ?? msg,
      isUser: !(isAdm),
      isAdmin: isAdm,
      time: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystem: data['isSystem'] as bool? ?? false,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'message': text,
    'text': text,
    'originalText': originalText,
    'isAdmin': isAdmin,
    'isSystem': isSystem,
    'createdAt': FieldValue.serverTimestamp(),
    'isRead': isRead,
  };
}

class ChatRoom {
  final String id;
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime lastTime;
  final int unreadCount;
  final bool isActive;
  final String language;

  ChatRoom({
    required this.id,
    required this.userId,
    required this.userName,
    this.lastMessage = '',
    required this.lastMessageAt,
    DateTime? lastTime,
    this.unreadCount = 0,
    this.isActive = true,
    this.language = 'ko',
  }) : lastTime = lastTime ?? lastMessageAt;

  factory ChatRoom.fromMap(String id, Map<String, dynamic> data) {
    final lastAt = (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ChatRoom(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '회원',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: lastAt,
      lastTime: lastAt,
      unreadCount: data['unreadCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      language: data['language'] as String? ?? 'ko',
    );
  }
}

class ChatService {
  static final _db = FirebaseFirestore.instance;

  /// 채팅방 생성 또는 기존 방 반환 (roomId 반환)
  static Future<String> getOrCreateRoom({
    required String userId,
    required String userName,
    String language = 'ko',
  }) async {
    try {
      final roomRef = _db.collection('chat_rooms').doc(userId);
      final doc = await roomRef.get();
      if (!doc.exists) {
        await roomRef.set({
          'userId': userId,
          'userName': userName,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
          'isActive': true,
          'language': language,
        });
      }
      return userId; // roomId = userId
    } catch (e) {
      if (kDebugMode) debugPrint('getOrCreateRoom error: $e');
      return userId;
    }
  }

  /// roomId 기반 메시지 스트림
  static Stream<List<ChatServiceMessage>> watchMessages(String roomId) {
    return _db
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        // orderBy 제거 → 인덱스 불필요, 메모리에서 정렬
        .snapshots()
        .map((snap) {
          final msgs = snap.docs
              .map((d) => ChatServiceMessage.fromMap(d.id, d.data()))
              .toList();
          // 메모리에서 시간순 정렬
          msgs.sort((a, b) => a.time.compareTo(b.time));
          return msgs;
        })
        .handleError((e) {
          if (kDebugMode) debugPrint('watchMessages error: $e');
          return <ChatServiceMessage>[];
        });
  }

  /// 메시지 전송 (roomId 방식)
  static Future<void> sendMessage({
    String? roomId,
    String? userId,
    String? senderId,     // chat_screen 호환
    required String senderName,
    String? message,
    String? text,         // chat_screen 호환 (text 파라미터)
    bool isAdmin = false,
    bool? isUser,         // chat_screen 호환 (isUser → isAdmin 역)
    String? originalText,
  }) async {
    final msg = message ?? text ?? '';
    final admin = isAdmin || (isUser == false);
    final targetId = roomId ?? userId ?? senderId ?? '';
    try {
      final batch = _db.batch();
      final msgRef = _db
          .collection('chats')
          .doc(targetId)
          .collection('messages')
          .doc();
      batch.set(msgRef, {
        'senderId': admin ? 'admin' : targetId,
        'senderName': admin ? '2FIT 고객센터' : senderName,
        'message': msg,
        'text': msg,
        'originalText': originalText ?? msg,
        'isAdmin': admin,
        'isSystem': false,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      final roomRef = _db.collection('chat_rooms').doc(targetId);
      // 관리자 메시지: unreadCount 0 리셋 (읽음 처리)
      // 사용자 메시지: unreadCount +1 증가
      final Map<String, dynamic> roomUpdate = {
        'userId': targetId,
        'lastMessage': msg,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };
      if (admin) {
        roomUpdate['unreadCount'] = 0; // 관리자가 답변하면 미읽음 초기화
      } else {
        roomUpdate['userName'] = senderName;
        roomUpdate['unreadCount'] = FieldValue.increment(1);
      }
      batch.set(roomRef, roomUpdate, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('sendMessage error: $e');
    }
  }

  /// 관리자 답변 (roomId 방식)
  static Future<void> adminReply({
    String? roomId,
    String? userId,
    String? text,
    String? message,
  }) async {
    final msg = text ?? message ?? '';
    final targetId = roomId ?? userId ?? '';
    await sendMessage(
      roomId: targetId,
      senderName: '2FIT 고객센터',
      message: msg,
      isAdmin: true,
    );
  }

  static Stream<List<ChatRoom>> watchAllRooms() {
    return _db
        .collection('chat_rooms')
        .snapshots()
        .map((snap) {
          final rooms = snap.docs
              .map((d) => ChatRoom.fromMap(d.id, d.data()))
              .toList();
          rooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          return rooms;
        })
        .handleError((e) {
          if (kDebugMode) debugPrint('watchAllRooms error: $e');
          return <ChatRoom>[];
        });
  }

  static Stream<List<ChatRoom>> watchAllChatRooms() => watchAllRooms();

  static Future<void> markAsRead(String userId) async {
    try {
      final snap = await _db
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('isAdmin', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.update(_db.collection('chat_rooms').doc(userId), {'unreadCount': 0});
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('markAsRead error: $e');
    }
  }

  static Future<void> markMessagesAsRead(String userId) => markAsRead(userId);

  /// 채팅 상담 완료 처리
  static Future<void> completeRoom(String roomId, {String completedBy = 'user'}) async {
    try {
      await _db.collection('chat_rooms').doc(roomId).update({
        'isActive': false,
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': completedBy,
      });
      // 완료 시스템 메시지 추가
      await _db.collection('chats').doc(roomId).collection('messages').add({
        'senderId': 'system',
        'senderName': '시스템',
        'message': completedBy == 'user' ? '상담이 종료되었습니다. 감사합니다!' : '관리자가 상담을 종료했습니다.',
        'text': completedBy == 'user' ? '상담이 종료되었습니다. 감사합니다!' : '관리자가 상담을 종료했습니다.',
        'originalText': completedBy == 'user' ? '상담이 종료되었습니다. 감사합니다!' : '관리자가 상담을 종료했습니다.',
        'isAdmin': false,
        'isSystem': true,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': true,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('completeRoom error: $e');
    }
  }

  /// 채팅방 완료 여부 확인
  static Stream<bool> watchRoomCompleted(String roomId) {
    return _db.collection('chat_rooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return false;
      return doc.data()?['isCompleted'] as bool? ?? false;
    }).handleError((_) => false);
  }

  static Future<int> getTotalUnreadCount() async {
    try {
      final snap = await _db.collection('chat_rooms').get();
      int total = 0;
      for (final doc in snap.docs) {
        total += (doc.data()['unreadCount'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('getTotalUnreadCount error: $e');
      return 0;
    }
  }

  static Stream<int> watchTotalUnreadCount() {
    return _db.collection('chat_rooms').snapshots().map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        total += (doc.data()['unreadCount'] as int? ?? 0);
      }
      return total;
    }).handleError((e) => 0);
  }
}

// 타입 앨리어스 (admin_screen 호환성)
typedef ChatRoomModel = ChatRoom;
typedef ChatMessageModel = ChatServiceMessage;
