import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';
import '../utils/app_localizations.dart';
import '../services/order_service.dart';
import '../services/email_service.dart';
import '../services/product_service.dart';
import '../services/review_service.dart';
import '../services/wishlist_coupon_service.dart';
import '../services/translation_service.dart';
import '../services/size_profile_service.dart';
import '../services/banner_service.dart';

// ── 언어 Provider ──────────────────────────────────────
class LanguageProvider extends ChangeNotifier {
  static const _kLangKey = 'selected_language';
  AppLanguage _language = AppLanguage.korean;

  AppLanguage get language => _language;
  AppLocalizations get loc => AppLocalizations(_language);

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLangKey);
      if (code != null) {
        final found = AppLanguage.values.where((l) => l.code == code).firstOrNull;
        if (found != null && found != _language) {
          _language = found;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    _saveLanguage(lang);
  }

  Future<void> _saveLanguage(AppLanguage lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLangKey, lang.code);
    } catch (_) {}
  }
}

// ── 관리자 계정 (하드코딩) ──────────────────────────────
const _kAdminAccounts = [
  {'email': 'chw243527@gmail.com',   'password': 'Admin2fit2024!',  'name': '관리자'},
  {'email': 'tbrk2435@naver.com', 'password': 'manager2fit', 'name': '매니저'},
];

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get shippingFee => subtotal >= 300000 ? 0 : 4000; // 30만원 이상 무료배송, 미만 4,000원
  double get total => subtotal + shippingFee;

  bool get isEmpty => _items.isEmpty;

  void addItem(ProductModel product, String size, String color, {int quantity = 1, double extraPrice = 0, Map<String, dynamic>? customOptions}) {
    // 단체주문/추가제작 아이템은 항상 새로 추가 (customOptions 다를 수 있음)
    final isGroupOrder = customOptions != null &&
        (customOptions['orderType'] == 'group' || customOptions['orderType'] == 'additional');
    if (!isGroupOrder) {
      final existingIndex = _items.indexWhere(
        (item) => item.product.id == product.id && item.selectedSize == size && item.selectedColor == color && item.extraPrice == extraPrice,
      );
      if (existingIndex >= 0) {
        _items[existingIndex].quantity += quantity;
        notifyListeners();
        return;
      }
    }
    _items.add(CartItem(
      id: '${product.id}_${size}_${color}_${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      selectedSize: size,
      selectedColor: color,
      quantity: quantity,
      extraPrice: extraPrice,
      customOptions: customOptions,
    ));
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _loginError;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get loginError => _loginError;

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// 이메일+비밀번호 로그인 (레거시 호환용 — AuthService로 대체됨)
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _loginError = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    final adminMatch = _kAdminAccounts.firstWhere(
      (a) => a['email'] == email.trim() && a['password'] == password,
      orElse: () => {},
    );
    if (adminMatch.isNotEmpty) {
      _user = UserModel(
        id: 'admin_${email.split('@').first}',
        name: adminMatch['name']!,
        email: email.trim(),
        phone: '02-0000-0000',
        isAdmin: true,
        createdAt: DateTime(2024, 1, 1),
      );
      _isLoading = false;
      notifyListeners();
      // 관리자 로그인 시 FCM 토큰 Firestore 등록 → Cloud Functions가 푸시 알림 발송
      _registerAdminFcmToken();
      return true;
    }
    if (email.isNotEmpty && password.length >= 6) {
      _user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email.trim(),
        phone: '',
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _loginError = '이메일 또는 비밀번호가 올바르지 않습니다.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void login(UserModel user) {
    _user = user;
    _loginError = null;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  // 관리자 FCM 토큰 등록 (Cloud Functions 트리거용)
  Future<void> _registerAdminFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) return;

      String? token;
      if (kIsWeb) {
        token = await messaging.getToken(
          vapidKey: 'BPOVoK3gRuXzSCDkS5jtfKFNV1PV3BXnJJXVlFJhk6KQQMK5zqJ_N3G5zYYsNJT1JoV7tKMvVsZJfS5rqF5o3M',
        ).catchError((_) => null);
      } else {
        token = await messaging.getToken();
      }
      if (token == null || token.isEmpty) return;

      // admin_fcm_tokens 컬렉션에 저장 → Cloud Functions가 자동 처리
      await FirebaseFirestore.instance.collection('admin_fcm_tokens').add({
        'token': token,
        'registeredAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'android',
      });
      if (kDebugMode) debugPrint('✅ 관리자 FCM 토큰 등록 완료');
    } catch (e) {
      if (kDebugMode) debugPrint('관리자 FCM 토큰 등록 실패: $e');
    }
  }

  Future<void> updateUserProfile({String? name, String? phone}) async {
    if (_user == null) return;
    _user = UserModel(
      id: _user!.id,
      name: name ?? _user!.name,
      email: _user!.email,
      phone: phone ?? _user!.phone,
      address: _user!.address,
      isAdmin: _user!.isAdmin,
      wishlist: _user!.wishlist,
      points: _user!.points,
      coupons: _user!.coupons,
      memberTier: _user!.memberTier,
      createdAt: _user!.createdAt,
      addresses: _user!.addresses,
    );
    notifyListeners();
    // Firestore 동기화
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 프로필 업데이트 실패: $e');
    }
  }

  void updateAddresses(List<AddressModel> addresses) {
    if (_user == null) return;
    _user = UserModel(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      phone: _user!.phone,
      address: _user!.address,
      isAdmin: _user!.isAdmin,
      wishlist: _user!.wishlist,
      points: _user!.points,
      coupons: _user!.coupons,
      memberTier: _user!.memberTier,
      createdAt: _user!.createdAt,
      addresses: addresses,
    );
    notifyListeners();
    // Firestore 동기화 (비동기, 실패해도 UI 즉시 반영)
    FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.id)
        .update({
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError(
      (e) { if (kDebugMode) debugPrint('⚠️ 주소 저장 실패: $e'); },
    );
  }

  void toggleWishlist(String productId) {
    if (_user == null) return;
    if (_user!.wishlist.contains(productId)) {
      _user!.wishlist.remove(productId);
    } else {
      _user!.wishlist.add(productId);
    }
    notifyListeners();
    // Firestore 동기화 (비동기, 실패해도 UI는 즉시 반영)
    WishlistService.toggleWishlist(_user!.id, productId).catchError(
      (e) { if (kDebugMode) debugPrint('⚠️ 찜 동기화 실패: $e'); },
    );
  }

  // 로그인 시 Firestore 찜 목록 동기화
  Future<void> syncWishlistFromFirestore() async {
    if (_user == null) return;
    try {
      final wishlist = await WishlistService.getWishlist(_user!.id);
      _user!.wishlist
        ..clear()
        ..addAll(wishlist);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 찜 목록 동기화 실패: $e');
    }
  }

  bool isInWishlist(String productId) {
    return _user?.wishlist.contains(productId) ?? false;
  }

  void addPoints(int amount) {
    if (_user == null) return;
    _user!.points += amount;
    notifyListeners();
  }

  void usePoints(int amount) {
    if (_user == null) return;
    _user!.points = (_user!.points - amount).clamp(0, 999999);
    notifyListeners();
  }
}

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<OrderModel> get myOrders => _orders.toList();

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
    // Firestore에 저장 + 이메일 발송 (백그라운드)
    Future(() async {
      try {
        await OrderService.saveOrder(order);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 주문 저장 실패: $e');
      }
      if (order.userEmail.isNotEmpty) {
        try {
          if (order.paymentMethod == '무통장입금') {
            await EmailService.sendBankTransferAdminAlert(order);
          }
          await EmailService.sendOrderConfirmEmail(order);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ 주문 이메일 발송 실패: $e');
        }
      }
    });
  }

  List<OrderModel> getUserOrders(String userId) {
    return _orders.where((o) => o.userId == userId).toList();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final old = _orders[index];
      _orders[index] = OrderModel(
        id: old.id,
        userId: old.userId,
        userName: old.userName,
        userEmail: old.userEmail,
        userPhone: old.userPhone,
        userAddress: old.userAddress,
        items: old.items,
        totalAmount: old.totalAmount,
        shippingFee: old.shippingFee,
        paymentMethod: old.paymentMethod,
        status: status,
        orderType: old.orderType,
        customOptions: old.customOptions,
        groupName: old.groupName,
        groupCount: old.groupCount,
        createdAt: old.createdAt,
        memo: old.memo,
        additionalOrderCount: old.additionalOrderCount,
        colorEditCount: old.colorEditCount,
        designRevisionCount: old.designRevisionCount,
        designRevisionDeadline: old.designRevisionDeadline,
      );
      notifyListeners();
    }
  }

  /// Hive에서 사용자 주문 로드 (앱 시작 시)
  Future<void> loadUserOrders(String userId) async {
    final saved = await OrderService.getUserOrders(userId);
    for (final order in saved) {
      if (!_orders.any((o) => o.id == order.id)) {
        _orders.add(order);
      }
    }
    notifyListeners();
  }

  /// Hive에서 전체 주문 로드 (관리자용)
  Future<void> loadAllOrders() async {
    final saved = await OrderService.getAllOrders();
    _orders.clear();
    _orders.addAll(saved);
    notifyListeners();
  }
}

// ── 쿠폰 Provider (Firestore 연동) ─────────────────────
class CouponProvider extends ChangeNotifier {
  List<CouponModel> _coupons = [];
  bool _loading = false;
  String? _userId;

  List<CouponModel> get coupons => List.unmodifiable(_coupons);
  List<CouponModel> get validCoupons => _coupons.where((c) => c.isValid).toList();
  bool get isLoading => _loading;

  // 로그인 후 내 쿠폰 로드
  void loadUserCoupons(String userId) {
    _userId = userId;
    _loading = true;
    notifyListeners();
    CouponService.watchMyCoupons(userId).listen((coupons) {
      _coupons = coupons;
      _loading = false;
      notifyListeners();
    }, onError: (e) {
      _loading = false;
      notifyListeners();
      if (kDebugMode) debugPrint('⚠️ 쿠폰 로드 실패: $e');
    });
  }

  // 쿠폰 코드 등록
  Future<String> registerByCode(String code) async {
    if (_userId == null) return '로그인이 필요합니다.';
    return await CouponService.registerCoupon(_userId!, code);
  }

  // 쿠폰 사용
  Future<void> useCoupon(String couponId) async {
    if (_userId == null) return;
    final idx = _coupons.indexWhere((c) => c.id == couponId);
    if (idx >= 0) {
      _coupons[idx].isUsed = true;
      notifyListeners();
    }
    await CouponService.useCoupon(_userId!, couponId);
  }

  // 로컬 추가 (호환성 유지)
  void addCoupon(CouponModel coupon) {
    if (!_coupons.any((c) => c.id == coupon.id)) {
      _coupons.add(coupon);
      notifyListeners();
    }
  }

  CouponModel? findByCode(String code) {
    try {
      return _coupons.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase() && c.isValid,
      );
    } catch (_) {
      return null;
    }
  }

  // 로그아웃 시 쿠폰 데이터 초기화
  void clear() {
    _coupons = [];
    _userId = null;
    notifyListeners();
  }
}

// ── 포인트 Provider ───────────────────────────────────
class PointProvider extends ChangeNotifier {
  final List<PointHistory> _history = [];
  int _totalPoints = 0;

  int get totalPoints => _totalPoints;
  List<PointHistory> get history => List.unmodifiable(_history);

  /// Firestore에서 포인트 데이터 로드
  Future<void> loadFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _totalPoints = (data['points'] as num?)?.toInt() ?? 0;
        final historyList = data['pointHistory'] as List<dynamic>? ?? [];
        _history
          ..clear()
          ..addAll(historyList.map((h) => PointHistory(
            id: h['id'] ?? '',
            type: h['type'] == 'earn' ? PointActionType.earn : PointActionType.use,
            amount: (h['amount'] as num?)?.toInt() ?? 0,
            description: h['description'] ?? '',
            createdAt: (h['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
          )));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 포인트 로드 실패: $e');
    }
  }

  void earnPoints(int amount, String description) {
    _totalPoints += amount;
    _history.insert(
      0,
      PointHistory(
        id: 'ph${DateTime.now().millisecondsSinceEpoch}',
        type: PointActionType.earn,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  bool usePoints(int amount, String description) {
    if (_totalPoints < amount) return false;
    _totalPoints -= amount;
    _history.insert(
      0,
      PointHistory(
        id: 'ph${DateTime.now().millisecondsSinceEpoch}',
        type: PointActionType.use,
        amount: -amount,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }
}

// ── 리뷰 Provider ─────────────────────────────────────
class ReviewProvider extends ChangeNotifier {
  // 로컬 캐시 (상품별)
  final Map<String, List<ReviewModel>> _cache = {};
  final Map<String, double> _ratings = {};

  List<ReviewModel> getProductReviews(String productId) =>
      _cache[productId] ?? [];

  double getProductRating(String productId) => _ratings[productId] ?? 0;

  // 상품별 실시간 스트림 구독
  Stream<List<ReviewModel>> watchProductReviews(String productId) {
    return ReviewService.watchProductReviews(productId)..listen((reviews) {
      _cache[productId] = reviews;
      if (reviews.isNotEmpty) {
        _ratings[productId] =
            reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;
      }
      notifyListeners();
    });
  }

  // 유저별 스트림 (마이페이지)
  Stream<List<ReviewModel>> watchUserReviews(String userId) =>
      ReviewService.watchUserReviews(userId);

  // 리뷰 추가
  Future<void> addReview(ReviewModel review) async {
    await ReviewService.addReview(review);
    final list = List<ReviewModel>.from(_cache[review.productId] ?? []);
    list.insert(0, review);
    _cache[review.productId] = list;
    if (list.isNotEmpty) {
      _ratings[review.productId] =
          list.fold(0.0, (s, r) => s + r.rating) / list.length;
    }
    notifyListeners();
  }

  // 리뷰 수정
  Future<void> updateReview(ReviewModel review) async {
    await ReviewService.updateReview(review);
    final list = _cache[review.productId] ?? [];
    final idx = list.indexWhere((r) => r.id == review.id);
    if (idx >= 0) {
      list[idx] = review;
      _cache[review.productId] = list;
      notifyListeners();
    }
  }

  // 리뷰 삭제
  Future<void> deleteReview(String reviewId, String productId) async {
    await ReviewService.deleteReview(reviewId, productId);
    final list = _cache[productId];
    if (list != null) {
      list.removeWhere((r) => r.id == reviewId);
      notifyListeners();
    }
  }
}

// ── 알림 모델 & Provider ──────────────────────────────
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // order, promo, info
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  /// Firestore에서 알림 로드
  Future<void> loadFromFirestore(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      final loaded = snapshot.docs.map((doc) {
        final d = doc.data();
        return NotificationModel(
          id: doc.id,
          title: d['title'] ?? '',
          body: d['body'] ?? '',
          type: d['type'] ?? 'info',
          isRead: d['isRead'] ?? false,
          createdAt: (d['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 알림 로드 실패: $e');
    }
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}

// ══════════════════════════════════════════════════════════════
// NoticeThemeHelper — 제목/내용 키워드 → 테마 자동 감지 + 이미지 매핑
// ══════════════════════════════════════════════════════════════
class NoticeThemeHelper {

  // ── A) 테마별 이모지 배너 (이미지 없을 때 텍스트 배너로 표시) ──
  static const Map<String, String> themeEmoji = {
    'general':  '📢',
    'event':    '🎉',
    'delivery': '🚚',
    'warning':  '⚠️',
    'update':   '✅',
    'promo':    '🛒',
    'holiday':  '🗓️',
    'weather':  '🌤️',
    'newitem':  '🆕',
    'review':   '⭐',
  };

  static const Map<String, String> themeLabel = {
    'general':  '일반 공지',
    'event':    '이벤트',
    'delivery': '배송 안내',
    'warning':  '주의 사항',
    'update':   '업데이트',
    'promo':    '할인/프로모션',
    'holiday':  '휴무/일정',
    'weather':  '날씨/계절',
    'newitem':  '신상품',
    'review':   '리뷰/후기',
  };

  // ── B) 테마별 일러스트 이미지 URL (무료 오픈소스 SVG — unDraw / OpenMoji) ──
  static const Map<String, String> themeImageUrl = {
    'holiday':  'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/1f4c5.svg',
    'event':    'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/1f389.svg',
    'delivery': 'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/1f69a.svg',
    'warning':  'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/26a0.svg',
    'update':   'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/2705.svg',
    'promo':    'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/1f6d2.svg',
    'newitem':  'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/1f195.svg',
    'weather':  'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/26c5.svg',
    'review':   'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/2b50.svg',
    'general':  '',  // 일반공지는 이미지 없음
  };

  // ── 키워드 → 테마 자동 감지 ──
  static String detectTheme(String title, String content) {
    final text = '${title.toLowerCase()} ${content.toLowerCase()}';

    // 휴무/일정 (달력)
    if (_has(text, ['휴무', '휴일', '공휴일', '달력', '일정', '영업시간', '운영시간',
                    '쉬는날', '명절', '연휴', '설날', '추석', '크리스마스'])) return 'holiday';

    // 이벤트
    if (_has(text, ['이벤트', '기념', '축제', '파티', '선물', '경품', '추첨',
                    'event', '기회', '특별'])) return 'event';

    // 배송
    if (_has(text, ['배송', '출고', '택배', '발송', '배달', '도착', '운송',
                    'delivery', '입고', '재고'])) return 'delivery';

    // 신상품
    if (_has(text, ['신상', '신제품', '새로운', '출시', '런칭', 'new', '신규'])) return 'newitem';

    // 할인/프로모
    if (_has(text, ['할인', '세일', '프로모', '쿠폰', '적립', '혜택', '특가',
                    'sale', '% off', '무료', '증정'])) return 'promo';

    // 주의/안내
    if (_has(text, ['주의', '경고', '중요', '긴급', '안전', '필독', '꼭 확인'])) return 'warning';

    // 업데이트
    if (_has(text, ['업데이트', '개선', '변경', '수정', '패치', '버전', '기능 추가'])) return 'update';

    // 날씨/계절
    if (_has(text, ['날씨', '기온', '여름', '겨울', '봄', '가을', '비', '눈', '더위', '추위'])) return 'weather';

    // 리뷰
    if (_has(text, ['리뷰', '후기', '평점', '만족', '추천'])) return 'review';

    return 'general';
  }

  static bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // ── 테마에 어울리는 자동 이미지 URL 반환 (없으면 빈 문자열) ──
  static String autoImageUrl(String theme) => themeImageUrl[theme] ?? '';
}

// ── 공지사항 Provider ──────────────────────────────────────
class NoticeModel {
  final String id;
  final String titleKo;
  final String contentKo;
  final Map<String, String> titleTranslations;
  final Map<String, String> contentTranslations;
  final bool isActive;
  final DateTime createdAt;
  /// 테마: 'general'|'event'|'delivery'|'warning'|'update'|'promo'
  final String theme;
  /// 본문 위에 표시할 이미지 URL (선택)
  final String imageUrl;

  const NoticeModel({
    required this.id,
    this.titleKo = '',
    this.contentKo = '',
    this.titleTranslations = const {},
    this.contentTranslations = const {},
    this.isActive = true,
    required this.createdAt,
    this.theme = 'general',
    this.imageUrl = '',
  });

  String localizedTitle(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return titleTranslations['en']?.isNotEmpty == true ? titleTranslations['en']! : titleKo;
      case AppLanguage.japanese:
        return titleTranslations['ja']?.isNotEmpty == true ? titleTranslations['ja']! : titleKo;
      case AppLanguage.chinese:
        return titleTranslations['zh']?.isNotEmpty == true ? titleTranslations['zh']! : titleKo;
      case AppLanguage.mongolian:
        return titleTranslations['mn']?.isNotEmpty == true ? titleTranslations['mn']! : titleKo;
      default:
        return titleKo;
    }
  }

  String localizedContent(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return contentTranslations['en']?.isNotEmpty == true ? contentTranslations['en']! : contentKo;
      case AppLanguage.japanese:
        return contentTranslations['ja']?.isNotEmpty == true ? contentTranslations['ja']! : contentKo;
      case AppLanguage.chinese:
        return contentTranslations['zh']?.isNotEmpty == true ? contentTranslations['zh']! : contentKo;
      case AppLanguage.mongolian:
        return contentTranslations['mn']?.isNotEmpty == true ? contentTranslations['mn']! : contentKo;
      default:
        return contentKo;
    }
  }

  factory NoticeModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return NoticeModel(
      id: id,
      titleKo: data['titleKo'] as String? ?? data['title'] as String? ?? '',
      contentKo: data['contentKo'] as String? ?? data['content'] as String? ?? '',
      titleTranslations: data['titleTranslations'] != null
          ? Map<String, String>.from(data['titleTranslations'] as Map)
          : const {},
      contentTranslations: data['contentTranslations'] != null
          ? Map<String, String>.from(data['contentTranslations'] as Map)
          : const {},
      isActive: data['isActive'] as bool? ?? true,
      createdAt: createdAt,
      theme: data['theme'] as String? ?? 'general',
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titleKo': titleKo,
    'contentKo': contentKo,
    'titleTranslations': titleTranslations,
    'contentTranslations': contentTranslations,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'theme': theme,
    'imageUrl': imageUrl,
  };
}

class NoticeProvider extends ChangeNotifier {
  bool _dismissedToday = false;
  DateTime? _dismissedDate;
  bool _isLoading = false;
  // 현재 로그인된 유저 UID (유저별 dismiss 키 분리용)
  String? _currentUid;

  static const String _kPopupDismissKey = 'popup_dismiss_date';

  // UID 포함 dismiss 키 → 유저별로 팝업 상태 분리
  String _dismissKey(String? uid) =>
      uid != null && uid.isNotEmpty ? '${_kPopupDismissKey}_$uid' : _kPopupDismissKey;

  /// 로그인한 유저가 바뀔 때 호출 — 새 유저의 dismiss 상태 로드
  Future<void> onUserChanged(String? uid) async {
    if (_currentUid == uid) return; // 같은 유저면 무시
    _currentUid = uid;
    // 상태 초기화 후 새 유저 기준으로 재로드
    _dismissedToday = false;
    _dismissedDate = null;
    notifyListeners();
    await loadDismissState(uid: uid);
  }

  /// 앱 시작 또는 유저 변경 시 SharedPreferences에서 닫기 날짜 복원
  Future<void> loadDismissState({String? uid}) async {
    final key = _dismissKey(uid ?? _currentUid);
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(key);
      if (saved != null) {
        final date = DateTime.tryParse(saved);
        if (date != null) {
          _dismissedDate = date;
          _dismissedToday = true;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  final List<NoticeModel> _notices = [
    NoticeModel(
      id: 'n001',
      titleKo: '2FIT MALL 오픈 안내 🎉',
      contentKo: '안녕하세요, 2FIT MALL을 찾아주셔서 감사합니다!\n\n🏃 러너를 위한 최고의 스포츠웨어 쇼핑몰\n✅ 기성품 즉시 구매 가능\n✅ 단체 커스텀 (5명~)\n\n📦 3만원 이상 주문 시 무료배송\n📞 문의: 카카오톡 @2FIT',
      titleTranslations: {
        'en': '2FIT MALL Grand Opening 🎉',
        'ja': '2FIT MALLオープンのご案内 🎉',
        'zh': '2FIT MALL 盛大开业 🎉',
        'mn': '2FIT MALL Нээлт 🎉',
      },
      contentTranslations: {
        'en': 'Welcome to 2FIT MALL!\n\n🏃 Best sportswear for runners\n✅ Ready-made items\n✅ Group custom (5+ people)\n✅ Personal custom (1 piece+)\n\n📦 Free shipping on orders over ₩30,000\n📞 Contact: KakaoTalk @2FIT',
        'ja': '2FIT MALLへようこそ！\n\n🏃 ランナーのためのスポーツウエア\n✅ 既製品即日購入\n✅ 団体カスタム（5名以上）\n✅ 個人カスタム（1枚~）\n\n📦 3万ウォン以上送料無料\n📞 お問合わせ: カカオトーク @2FIT',
        'zh': '欢迎来到2FIT MALL！\n\n🏃 专为跑者打造的运动服饰\n✅ 成衣现货即买\n✅ 团体定制（5人起订）\n✅ 个人定制（1件起）\n\n📦 充₩30,000免费配送\n📞 联系: KakaoTalk @2FIT',
        'mn': 'Тавтай морилно уу!\n\n🏃 Гүйгчдэд зориулсан спортын хувцас\n✅ Бэлэн барааг шууд захиалах\n✅ Бүгийн захиалга (5+ хүн)\n✅ Хувийн захиалга (1ш-ааас)\n\n📦 30,000₩-аас дээш үнэгүй хүргэлт\n📞 KakaoTalk @2FIT',
      },
      isActive: true,
      createdAt: DateTime(2025, 1, 1),
    ),
  ];

  List<NoticeModel> get activeNotices => _notices.where((n) => n.isActive).toList();
  bool get isLoading => _isLoading;

  bool get shouldShow {
    if (_dismissedToday && _dismissedDate != null) {
      final now = DateTime.now();
      if (_dismissedDate!.year == now.year &&
          _dismissedDate!.month == now.month &&
          _dismissedDate!.day == now.day) {
        return false;
      }
    }
    return activeNotices.isNotEmpty;
  }

  void markShown() {}

  Future<void> dismissToday() async {
    _dismissedToday = true;
    _dismissedDate = DateTime.now();
    // UID 포함 키로 저장 → 유저별 독립 관리
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissKey(_currentUid), _dismissedDate!.toIso8601String());
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadFromFirestore() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs
            .map((d) => NoticeModel.fromFirestore(d.data(), d.id))
            .toList();
        // 메모리에서 최신순 정렬 (Firestore 복합 인덱스 불필요)
        loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _notices.removeWhere((n) => n.id == 'n001');
        for (final n in loaded) {
          final idx = _notices.indexWhere((e) => e.id == n.id);
          if (idx >= 0) {
            _notices[idx] = n;
          } else {
            _notices.insert(0, n);
          }
        }
        _autoTranslateNotices(loaded);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('공지사항 Firestore 로드 실패: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _autoTranslateNotices(List<NoticeModel> notices) async {
    for (final notice in notices) {
      final needsTitle = notice.titleTranslations.isEmpty || !notice.titleTranslations.containsKey('en');
      final needsContent = notice.contentTranslations.isEmpty || !notice.contentTranslations.containsKey('en');
      if (!needsTitle && !needsContent) continue;
      try {
        Map<String, String> titleT = notice.titleTranslations;
        Map<String, String> contentT = notice.contentTranslations;
        if (needsTitle && notice.titleKo.isNotEmpty) {
          titleT = await TranslationService.translateWithCache(notice.titleKo);
        }
        if (needsContent && notice.contentKo.isNotEmpty) {
          contentT = await TranslationService.translateLongText(notice.contentKo);
        }
        if (titleT.isNotEmpty || contentT.isNotEmpty) {
          final updateData = <String, dynamic>{};
          if (titleT.isNotEmpty) updateData['titleTranslations'] = titleT;
          if (contentT.isNotEmpty) updateData['contentTranslations'] = contentT;
          await FirebaseFirestore.instance
              .collection('notices')
              .doc(notice.id)
              .set(updateData, SetOptions(merge: true));
          final idx = _notices.indexWhere((n) => n.id == notice.id);
          if (idx >= 0) {
            final old = _notices[idx];
            _notices[idx] = NoticeModel(
              id: old.id,
              titleKo: old.titleKo,
              contentKo: old.contentKo,
              titleTranslations: titleT.isNotEmpty ? titleT : old.titleTranslations,
              contentTranslations: contentT.isNotEmpty ? contentT : old.contentTranslations,
              isActive: old.isActive,
              createdAt: old.createdAt,
              theme: old.theme,
              imageUrl: old.imageUrl,
            );
            notifyListeners();
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('공지 자동번역 실패 (${notice.id}): $e');
      }
    }
  }

  void addNotice(NoticeModel notice) {
    _notices.insert(0, notice);
    notifyListeners();
  }

  void removeNotice(String id) {
    _notices.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ── Firestore 저장 (신규 등록 + 수정 공용) ──
  Future<void> saveNotice(NoticeModel notice) async {
    try {
      await FirebaseFirestore.instance
          .collection('notices')
          .doc(notice.id)
          .set(notice.toFirestore(), SetOptions(merge: true));
      // 로컬 목록 갱신
      final idx = _notices.indexWhere((n) => n.id == notice.id);
      if (idx >= 0) {
        _notices[idx] = notice;
      } else {
        _notices.insert(0, notice);
      }
      notifyListeners();
      _autoTranslateNotices([notice]);
    } catch (e) {
      if (kDebugMode) debugPrint('공지 저장 실패: $e');
      rethrow;
    }
  }

  // ── Firestore 삭제 ──
  Future<void> deleteNotice(String id) async {
    try {
      await FirebaseFirestore.instance.collection('notices').doc(id).delete();
      _notices.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('공지 삭제 실패: $e');
      rethrow;
    }
  }

  // ── 활성/비활성 토글 ──
  Future<void> toggleNoticeActive(String id) async {
    final idx = _notices.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final old = _notices[idx];
    final updated = NoticeModel(
      id: old.id,
      titleKo: old.titleKo,
      contentKo: old.contentKo,
      titleTranslations: old.titleTranslations,
      contentTranslations: old.contentTranslations,
      isActive: !old.isActive,
      createdAt: old.createdAt,
    );
    _notices[idx] = updated;
    notifyListeners();
    try {
      await FirebaseFirestore.instance
          .collection('notices')
          .doc(id)
          .update({'isActive': updated.isActive});
    } catch (e) {
      // 실패 시 롤백
      _notices[idx] = old;
      notifyListeners();
      if (kDebugMode) debugPrint('공지 토글 실패: $e');
    }
  }

  // ── 전체 공지 로드 (관리자용 – 비활성 포함) ──
  Future<void> loadAllForAdmin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs
            .map((d) => NoticeModel.fromFirestore(d.data(), d.id))
            .toList();
        _notices.clear();
        _notices.addAll(loaded);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('공지 전체 로드 실패: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  List<NoticeModel> get allNotices => List.unmodifiable(_notices);
}

// ── 상품 Provider (로컬 데이터 기반) ──────────────────────────────
class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _adminProducts = [];
  List<ProductModel> _groupOnlyProducts = []; // 단체주문 전용 상품
  bool _isLoading = false;
  bool _isAdminLoading = false;
  bool _isGroupOnlyLoading = false; // 단체주문 전용 로딩 상태
  String? _error;
  String _currentCategory = '전체';
  /// 상품ID → 실제 판매 수량 캐시
  Map<String, int> _salesCountMap = {};
  /// 판매 수 집계 로드 완료 여부
  bool _salesCountsLoaded = false;

  List<ProductModel> get products => _products;
  /// 관리자 전용: isActive 무관 전체 상품 목록
  List<ProductModel> get adminProducts => _adminProducts;
  /// 단체주문 전용 상품 목록 (isGroupOnly=true, isActive=true)
  List<ProductModel> get groupOnlyProducts => _groupOnlyProducts;
  bool get isLoading => _isLoading;
  bool get isAdminLoading => _isAdminLoading;
  bool get isGroupOnlyLoading => _isGroupOnlyLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;
  /// 판매 수 집계 로드 완료 여부 (홈화면 베스트 섹션 로딩 표시용)
  bool get salesCountsLoaded => _salesCountsLoaded;

  /// 취소·환불 제외 실구매 기준 판매량 상위 상품 (salesCount > 0 인 것만)
  /// - 집계 로드 전(_salesCountsLoaded=false)이면 빈 리스트 반환 → 섹션 숨김
  /// - 로드 후 실구매 이력 없으면 빈 리스트 → 섹션 숨김
  List<ProductModel> get bestProducts {
    if (!_salesCountsLoaded) return [];
    final withSales = _products
        .where((p) => p.isActive && (_salesCountMap[p.id] ?? p.salesCount) > 0)
        .toList()
      ..sort((a, b) {
        final sa = _salesCountMap[a.id] ?? a.salesCount;
        final sb = _salesCountMap[b.id] ?? b.salesCount;
        return sb.compareTo(sa);
      });
    return withSales.take(10).toList();
  }

  ProductProvider() {
    // 즉시 더미/캐시 데이터 표시 — 절대 빈 리스트 아님
    _products = ProductService.getAllProductsGuaranteed();
    _adminProducts = ProductService.getAllProductsGuaranteed();
    _loadCategory('전체');
    // 실제 판매 수 집계 비동기 로드
    _loadSalesCounts();
    // 단체주문 전용 상품 로드
    loadGroupOnlyProducts();
  }

  /// 단체주문 전용 상품을 Firestore에서 직접 로드
  Future<void> loadGroupOnlyProducts() async {
    _isGroupOnlyLoading = true;
    notifyListeners();
    try {
      final prods = await ProductService.getGroupOnlyProducts();
      _groupOnlyProducts = prods;
      _isGroupOnlyLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 단체주문 전용 상품 로드 실패: $e');
      _isGroupOnlyLoading = false;
      // 폴백: 전체 상품에서 필터링
      _groupOnlyProducts = _products
          .where((p) => p.isGroupOnly && p.isActive)
          .toList();
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    _loadCategory(category);
  }

  Future<void> _loadCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final prods = category == '전체'
          ? await ProductService.getAllProducts()
              .timeout(const Duration(seconds: 12))
          : await ProductService.getProductsByCategory(category)
              .timeout(const Duration(seconds: 12));
      _products = prods;
      ProductService.updateCache(prods);
      _isLoading = false;
      _error = null;
      notifyListeners();
      // 번역 없는 상품은 백그라운드에서 자동 번역
      _autoTranslateMissingProducts(prods);
    } catch (e) {
      // Firestore 실패 시 더미 데이터로 폴백
      _isLoading = false;
      _error = null;
      // 항상 폴백 — 기존 products가 더미여도 최신 캐시로 교체
      final fallback = category == '전체'
          ? ProductService.getAllProductsSync()
          : ProductService.getProductsByCategorySync(category);
      if (_products.isEmpty || fallback.isNotEmpty) {
        _products = fallback;
      }
      notifyListeners(); // ← 반드시 호출해야 UI 갱신
      return;
    }
    notifyListeners();
  }

  /// 번역이 없는 상품에 대해 백그라운드 자동 번역 수행
  Future<void> _autoTranslateMissingProducts(List<ProductModel> prods) async {
    for (final product in prods) {
      final needsNameTranslation = product.nameTranslations.isEmpty ||
          !product.nameTranslations.containsKey('en') ||
          (product.nameTranslations['en']?.isEmpty ?? true);
      final needsDescTranslation = product.descriptionTranslations.isEmpty ||
          !product.descriptionTranslations.containsKey('en') ||
          (product.descriptionTranslations['en']?.isEmpty ?? true);

      if (!needsNameTranslation && !needsDescTranslation) continue;

      try {
        Map<String, String> nameT = product.nameTranslations;
        Map<String, String> descT = product.descriptionTranslations;

        if (needsNameTranslation) {
          nameT = await TranslationService.translateWithCache(product.name);
        }
        if (needsDescTranslation && product.description.isNotEmpty) {
          descT = await TranslationService.translateLongText(product.description);
        }

        if (nameT.isNotEmpty || descT.isNotEmpty) {
          final updatedProduct = product.copyWithTranslations(
            nameTranslations: nameT.isNotEmpty ? nameT : null,
            descriptionTranslations: descT.isNotEmpty ? descT : null,
          );
          // Firestore에 번역 저장
          await ProductService.updateTranslations(
            productId: product.id,
            nameTranslations: nameT.isNotEmpty ? nameT : null,
            descriptionTranslations: descT.isNotEmpty ? descT : null,
          );
          // 로컬 목록도 업데이트
          final idx = _products.indexWhere((p) => p.id == product.id);
          if (idx >= 0) {
            _products[idx] = updatedProduct;
            notifyListeners();
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('자동번역 실패 (${product.id}): $e');
      }
    }
  }

  /// 실제 구매 집계 (취소·환불 제외 전 주문 → productId별 수량 합산)
  Future<void> _loadSalesCounts() async {
    try {
      _salesCountMap = await OrderService.getSalesCountMap();
    } catch (_) {
      _salesCountMap = {};
    } finally {
      _salesCountsLoaded = true;
      notifyListeners();
    }
  }

  /// 외부에서 강제 갱신 (주문 상태 변경 후 호출)
  Future<void> refreshSalesCounts() => _loadSalesCounts();

  Future<void> refresh() async {
    // _loaded 플래그를 초기화하여 Firestore에서 강제 재로드
    // (이미 _loaded=true인 경우에도 최신 데이터를 가져옴)
    await ProductService.forceReloadFromFirestore();
    // forceReloadFromFirestore가 이미 전체 상품을 로드했으므로
    // _loadCategory는 캐시를 그대로 읽어 _products에 세팅하고 notifyListeners() 호출
    await _loadCategory(_currentCategory);
    await _loadSalesCounts();
  }

  /// 카테고리 상세 화면 전용: 항상 '전체' 상품을 Firestore에서 강제 재로드.
  /// _currentCategory가 무엇이든 상관없이 전체 상품 목록을 가져오므로
  /// CategoryDetailScreen의 _getProducts(filter) 필터링이 올바르게 작동함.
  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      await ProductService.forceReloadFromFirestore();
      final prods = await ProductService.getAllProducts();
      _products = prods;
      ProductService.updateCache(prods);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      final fallback = ProductService.getAllProductsSync();
      if (_products.isEmpty || fallback.isNotEmpty) {
        _products = fallback;
      }
      notifyListeners();
    }
  }

  /// 관리자 전용: isActive 무관 전체 상품 새로 로드
  Future<void> loadAdminProducts() async {
    _isAdminLoading = true;
    notifyListeners();
    try {
      final all = await ProductService.getAllProductsForAdmin();
      _adminProducts = all;
      _isAdminLoading = false;
      notifyListeners();
    } catch (e) {
      _isAdminLoading = false;
      _adminProducts = ProductService.getAllProductsSync();
      notifyListeners();
      if (kDebugMode) debugPrint('관리자 상품 로드 실패: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    await ProductService.addProduct(product);
    await refresh();
    await loadAdminProducts();
  }

  Future<bool> updateProduct(ProductModel product) async {
    final result = await ProductService.updateProduct(product);
    await refresh();
    await loadAdminProducts();
    return result;
  }

  Future<bool> deleteProduct(String id) async {
    // 1) 메모리에서 즉시 제거 → UI 즉시 반영
    _adminProducts.removeWhere((p) => p.id == id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    // 2) Firestore 실제 삭제
    final result = await ProductService.deleteProduct(id);
    // 3) 삭제 성공 여부와 무관하게 최신 목록으로 재동기화
    await loadAdminProducts();
    return result;
  }

  /// 섹션 이미지 업데이트 → 즉시 notifyListeners (상세 페이지 실시간 반영)
  Future<bool> updateSectionImages(
      String productId, String sectionKey, List<String> urls) async {
    final result =
        await ProductService.updateSectionImages(productId, sectionKey, urls);
    if (result) {
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx >= 0) {
        final p = _products[idx];
        final newMap = Map<String, List<String>>.from(p.sectionImages);
        if (urls.isEmpty) {
          newMap.remove(sectionKey);
        } else {
          newMap[sectionKey] = List<String>.from(urls);
        }
        _products[idx] = p.copyWithSectionImages(newMap);
        notifyListeners();
      }
    }
    return result;
  }

  /// 메인 이미지 업데이트 → 즉시 notifyListeners
  Future<bool> updateMainImages(
      String productId, List<String> urls) async {
    final result =
        await ProductService.updateMainImages(productId, urls);
    if (result) {
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx >= 0) {
        final p = _products[idx];
        _products[idx] = ProductModel(
          id: p.id, name: p.name, category: p.category,
          subCategory: p.subCategory,
          price: p.price, originalPrice: p.originalPrice,
          description: p.description, images: urls,
          sizes: p.sizes, colors: p.colors, material: p.material,
          isNew: p.isNew, newExpiresAt: p.newExpiresAt,
          isSale: p.isSale, isFreeShipping: p.isFreeShipping,
          isGroupOnly: p.isGroupOnly,
          isActive: p.isActive,
          rating: p.rating, reviewCount: p.reviewCount, stockCount: p.stockCount,
          salesCount: p.salesCount,
          createdAt: p.createdAt, sectionImages: p.sectionImages,
        );
        notifyListeners();
      }
    }
    return result;
  }
}


// ══════════════════════════════════════════════════════
// SizeProfileProvider — 사이즈 프로필 상태 관리
// ══════════════════════════════════════════════════════
class SizeProfileProvider extends ChangeNotifier {
  List<SizeProfile> _profiles = [];
  bool _loading = false;
  String? _error;

  List<SizeProfile> get profiles => List.unmodifiable(_profiles);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasProfiles => _profiles.isNotEmpty;

  /// 로그인 후 호출 — Firestore 실시간 스트림 구독
  void loadProfiles(String userId) {
    _loading = true;
    notifyListeners();
    SizeProfileService.watchProfiles(userId).listen(
      (list) {
        _profiles = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  /// 저장 (신규 or 수정)
  Future<String?> saveProfile(String userId, SizeProfile profile) async {
    try {
      if (_profiles.length >= SizeProfileService.maxProfiles &&
          profile.id.isEmpty) {
        return '사이즈 프로필은 최대 ${SizeProfileService.maxProfiles}개까지 저장할 수 있습니다.';
      }
      await SizeProfileService.saveProfile(userId, profile);
      return null; // 성공
    } catch (e) {
      return e.toString();
    }
  }

  /// 삭제
  Future<String?> deleteProfile(String userId, String profileId) async {
    try {
      await SizeProfileService.deleteProfile(userId, profileId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// 로그아웃 시 초기화
  void clear() {
    _profiles = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }
}


// ── 배너 Provider ─────────────────────────────────────────────────────────
/// Firestore /banners 컬렉션 실시간 구독.
/// HomeScreen·AdminScreen 양쪽이 동일한 데이터를 참조한다.
class BannerProvider extends ChangeNotifier {
  List<BannerModel> _banners = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<BannerModel>>? _bannerSub;

  List<BannerModel> get banners => _banners;
  bool get loading => _loading;
  String? get error => _error;

  /// 홈 화면에서 표시할 활성 배너 (active==true, order 정렬)
  List<BannerModel> get activeBanners {
    final active = _banners.where((b) => b.active).toList();
    // order 기준 정렬 (이미 서비스에서 정렬되지만 이중 보장)
    active.sort((a, b) => a.order.compareTo(b.order));
    return active;
  }

  BannerProvider() {
    _init();
  }

  void _init() async {
    // 기본 데이터 없으면 시드 (에러 무시 - 이미 데이터 있으면 스킵됨)
    try {
      await BannerService.seedDefaultBanners();
    } catch (e) {
      if (kDebugMode) debugPrint('BannerProvider: seedDefaultBanners error: $e');
    }

    // 기존 구독 취소 후 재구독
    await _bannerSub?.cancel();
    _bannerSub = BannerService.watchAllBanners().listen(
      (list) {
        _banners = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('BannerProvider stream error: $e');
        _error = e.toString();
        _loading = false;
        notifyListeners();
        // 에러 발생 시 3초 후 재시도
        Future.delayed(const Duration(seconds: 3), _retryStream);
      },
    );
  }

  /// 스트림 에러 발생 시 재연결 시도
  void _retryStream() {
    if (_banners.isNotEmpty) return; // 이미 데이터 있으면 재시도 불필요
    if (kDebugMode) debugPrint('BannerProvider: retrying stream connection...');
    _bannerSub?.cancel();
    _bannerSub = BannerService.watchAllBanners().listen(
      (list) {
        _banners = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('BannerProvider retry error: $e');
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _bannerSub?.cancel();
    super.dispose();
  }
}
