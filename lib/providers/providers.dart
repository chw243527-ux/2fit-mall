import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/app_localizations.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/review_service.dart';
import '../services/wishlist_coupon_service.dart';
import '../services/translation_service.dart';

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
  {'email': 'admin@2fit.co.kr',   'password': 'admin2fit!',  'name': '관리자'},
  {'email': 'manager@2fit.co.kr', 'password': 'manager2fit', 'name': '매니저'},
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
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize == size && item.selectedColor == color && item.extraPrice == extraPrice,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: '${product.id}_${size}_${color}_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        selectedSize: size,
        selectedColor: color,
        quantity: quantity,
        extraPrice: extraPrice,
        customOptions: customOptions,
      ));
    }
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
  final List<OrderModel> _orders = _generateSampleOrders();

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<OrderModel> get myOrders => _orders.toList();

  static List<OrderModel> _generateSampleOrders() {
    return [
      OrderModel(
        id: 'ORD-001',
        userId: 'user_001',
        userName: '김민지',
        userPhone: '010-1234-5678',
        userAddress: '서울시 강남구 역삼동 123-45',
        items: [
          OrderItem(
            productId: 'p001',
            productName: '2FIT 라운드넥 티셔츠',
            size: 'M',
            color: 'Black',
            quantity: 2,
            price: 35000,
          ),
          OrderItem(
            productId: 'p009',
            productName: '2FIT 롱 레깅스',
            size: 'M',
            color: 'Black',
            quantity: 1,
            price: 45000,
          ),
        ],
        totalAmount: 115000,
        paymentMethod: '카카오페이',
        status: OrderStatus.delivered,
        orderType: 'personal',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      OrderModel(
        id: 'ORD-002',
        userId: 'user_001',
        userName: '김민지',
        userPhone: '010-1234-5678',
        userAddress: '서울시 강남구 역삼동 123-45',
        items: [
          OrderItem(
            productId: 'p012',
            productName: '2FIT 크롭탑+숏레깅스 세트',
            size: 'S',
            color: 'Navy',
            quantity: 1,
            price: 58000,
          ),
        ],
        totalAmount: 58000,
        paymentMethod: '신용/체크카드',
        status: OrderStatus.shipped,
        orderType: 'personal',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
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
}

// ── 포인트 Provider ───────────────────────────────────
class PointProvider extends ChangeNotifier {
  final List<PointHistory> _history = _generateSampleHistory();
  int _totalPoints = 3200;

  int get totalPoints => _totalPoints;
  List<PointHistory> get history => List.unmodifiable(_history);

  static List<PointHistory> _generateSampleHistory() {
    return [
      PointHistory(
        id: 'ph001',
        type: PointActionType.earn,
        amount: 1000,
        description: 'ORD-001 구매 적립',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      PointHistory(
        id: 'ph002',
        type: PointActionType.earn,
        amount: 580,
        description: 'ORD-002 구매 적립',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PointHistory(
        id: 'ph003',
        type: PointActionType.earn,
        amount: 1620,
        description: '리뷰 작성 보너스',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
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
  final List<NotificationModel> _notifications = _generateSampleNotifications();

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  static List<NotificationModel> _generateSampleNotifications() {
    return [
      NotificationModel(
        id: 'n001',
        title: '주문이 확인되었습니다',
        body: 'ORD-002 주문이 제작 준비 중입니다.',
        type: 'order',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'n002',
        title: '신규 상품 입고!',
        body: '2FIT 여름 시즌 신상품이 입고되었습니다. 지금 확인해보세요!',
        type: 'promo',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      NotificationModel(
        id: 'n003',
        title: '쿠폰 발급',
        body: '신규 회원 웰컴 쿠폰이 발급되었습니다. WELCOME2FIT',
        type: 'promo',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'n004',
        title: '포인트 적립',
        body: '구매 적립 포인트 1,580P가 지급되었습니다.',
        type: 'info',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
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

// ── 공지사항 Provider ──────────────────────────────────────
class NoticeModel {
  final String id;
  final String titleKo;
  final String contentKo;
  final Map<String, String> titleTranslations;
  final Map<String, String> contentTranslations;
  final bool isActive;
  final DateTime createdAt;

  const NoticeModel({
    required this.id,
    this.titleKo = '',
    this.contentKo = '',
    this.titleTranslations = const {},
    this.contentTranslations = const {},
    this.isActive = true,
    required this.createdAt,
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
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titleKo': titleKo,
    'contentKo': contentKo,
    'titleTranslations': titleTranslations,
    'contentTranslations': contentTranslations,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class NoticeProvider extends ChangeNotifier {
  bool _dismissedToday = false;
  DateTime? _dismissedDate;
  bool _isLoading = false;

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

  void dismissToday() {
    _dismissedToday = true;
    _dismissedDate = DateTime.now();
    notifyListeners();
  }

  Future<void> loadFromFirestore() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs
            .map((d) => NoticeModel.fromFirestore(d.data(), d.id))
            .toList();
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
  bool _isLoading = false;
  bool _isAdminLoading = false;
  String? _error;
  String _currentCategory = '전체';

  List<ProductModel> get products => _products;
  /// 관리자 전용: isActive 무관 전체 상품 목록
  List<ProductModel> get adminProducts => _adminProducts;
  bool get isLoading => _isLoading;
  bool get isAdminLoading => _isAdminLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;

  ProductProvider() {
    // 즉시 더미 데이터 표시 (Firestore 로드 전에도 상품이 보이도록)
    _products = ProductService.getAllProductsSync();
    _adminProducts = ProductService.getAllProductsSync();
    _loadCategory('전체');
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
      if (_products.isEmpty) {
        // 더미 데이터 직접 사용 (동기)
        _products = category == '전체'
            ? ProductService.getAllProductsSync()
            : ProductService.getProductsByCategorySync(category);
      }
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

  Future<void> refresh() async => _loadCategory(_currentCategory);

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
          isNew: p.isNew, isSale: p.isSale, isFreeShipping: p.isFreeShipping,
          isGroupOnly: p.isGroupOnly,
          isActive: p.isActive,
          rating: p.rating, reviewCount: p.reviewCount, stockCount: p.stockCount,
          createdAt: p.createdAt, sectionImages: p.sectionImages,
        );
        notifyListeners();
      }
    }
    return result;
  }
}
