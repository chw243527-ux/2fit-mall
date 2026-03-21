import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final String subCategory; // 하위 카테고리 (예: '롱 레깅스', '숏 레깅스')
  final double price;
  final double? originalPrice;
  final String description;
  final List<String> images;
  final List<String> sizes;
  final List<String> colors;
  final String material;
  final bool isNew;
  final bool isSale;
  final bool isFreeShipping;
  final bool isGroupOnly; // 단체주문 전용 상품
  final double rating;
  final int reviewCount;
  final int stockCount;
  final bool isActive;
  final DateTime createdAt;
  // 섹션별 관리자 업로드 이미지 (key: 's1','s2','s3','s4','s5','s6')
  final Map<String, List<String>> sectionImages;
  // 다국어 상품명 번역 (key: 'en','ja','zh','mn')
  final Map<String, String> nameTranslations;
  // 다국어 상품 설명 번역 (key: 'en','ja','zh','mn')
  final Map<String, String> descriptionTranslations;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory = '',
    required this.price,
    this.originalPrice,
    required this.description,
    required this.images,
    required this.sizes,
    required this.colors,
    this.material = '78% Nylon, 22% Spandex / 4-way Stretch',
    this.isNew = false,
    this.isSale = false,
    this.isFreeShipping = false,
    this.isGroupOnly = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stockCount = 100,
    this.isActive = true,
    required this.createdAt,
    this.sectionImages = const {},
    this.nameTranslations = const {},
    this.descriptionTranslations = const {},
  });

  /// 현재 언어에 맞는 상품명 반환 (번역 없으면 원본 한국어 사용)
  String localizedName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return nameTranslations['en']?.isNotEmpty == true ? nameTranslations['en']! : name;
      case AppLanguage.japanese:
        return nameTranslations['ja']?.isNotEmpty == true ? nameTranslations['ja']! : name;
      case AppLanguage.chinese:
        return nameTranslations['zh']?.isNotEmpty == true ? nameTranslations['zh']! : name;
      case AppLanguage.mongolian:
        return nameTranslations['mn']?.isNotEmpty == true ? nameTranslations['mn']! : name;
      default:
        return name;
    }
  }

  /// 현재 언어에 맞는 상품 설명 반환 (번역 없으면 원본 한국어 사용)
  String localizedDescription(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return descriptionTranslations['en']?.isNotEmpty == true
            ? descriptionTranslations['en']!
            : description;
      case AppLanguage.japanese:
        return descriptionTranslations['ja']?.isNotEmpty == true
            ? descriptionTranslations['ja']!
            : description;
      case AppLanguage.chinese:
        return descriptionTranslations['zh']?.isNotEmpty == true
            ? descriptionTranslations['zh']!
            : description;
      case AppLanguage.mongolian:
        return descriptionTranslations['mn']?.isNotEmpty == true
            ? descriptionTranslations['mn']!
            : description;
      default:
        return description;
    }
  }

  /// 번역 데이터만 업데이트한 새 ProductModel 반환
  ProductModel copyWithTranslations({
    Map<String, String>? nameTranslations,
    Map<String, String>? descriptionTranslations,
  }) {
    return ProductModel(
      id: id, name: name, category: category, subCategory: subCategory,
      price: price, originalPrice: originalPrice, description: description,
      images: images, sizes: sizes, colors: colors, material: material,
      isNew: isNew, isSale: isSale, isFreeShipping: isFreeShipping,
      isGroupOnly: isGroupOnly, rating: rating, reviewCount: reviewCount,
      stockCount: stockCount, isActive: isActive, createdAt: createdAt,
      sectionImages: sectionImages,
      nameTranslations: nameTranslations ?? this.nameTranslations,
      descriptionTranslations: descriptionTranslations ?? this.descriptionTranslations,
    );
  }

  /// 가격을 항상 한국 원화(KRW) 형식으로 반환
  static String formatKRW(double price) {
    final intPrice = price.toInt();
    final s = intPrice.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }

  int get discountPercent {
    if (originalPrice != null && originalPrice! > price) {
      return (((originalPrice! - price) / originalPrice!) * 100).round();
    }
    return 0;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // sectionImages 역직렬화: Map<String, dynamic> → Map<String, List<String>>
    Map<String, List<String>> parseSectionImages(dynamic raw) {
      if (raw == null) return {};
      final map = raw as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, List<String>.from(v as List)));
    }

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subCategory: json['subCategory'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      description: json['description'] as String,
      images: List<String>.from(json['images'] as List),
      sizes: List<String>.from(json['sizes'] as List),
      colors: List<String>.from(json['colors'] as List),
      material: json['material'] as String? ?? '78% Nylon, 22% Spandex',
      isNew: json['isNew'] as bool? ?? false,
      isSale: json['isSale'] as bool? ?? false,
      isFreeShipping: json['isFreeShipping'] as bool? ?? false,
      isGroupOnly: json['isGroupOnly'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      stockCount: json['stockCount'] as int? ?? 100,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sectionImages: parseSectionImages(json['sectionImages']),
      nameTranslations: json['nameTranslations'] != null
          ? Map<String, String>.from(json['nameTranslations'] as Map)
          : const {},
      descriptionTranslations: json['descriptionTranslations'] != null
          ? Map<String, String>.from(json['descriptionTranslations'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'price': price,
      'originalPrice': originalPrice,
      'description': description,
      'images': images,
      'sizes': sizes,
      'colors': colors,
      'material': material,
      'isNew': isNew,
      'isSale': isSale,
      'isFreeShipping': isFreeShipping,
      'isGroupOnly': isGroupOnly,
      'rating': rating,
      'reviewCount': reviewCount,
      'stockCount': stockCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'sectionImages': sectionImages,
      'nameTranslations': nameTranslations,
      'descriptionTranslations': descriptionTranslations,
    };
  }

  /// 섹션 이미지만 변경한 새 ProductModel 반환
  ProductModel copyWithSectionImages(Map<String, List<String>> newSectionImages) {
    return ProductModel(
      id: id, name: name, category: category, subCategory: subCategory,
      price: price, originalPrice: originalPrice, description: description,
      images: images, sizes: sizes, colors: colors, material: material,
      isNew: isNew, isSale: isSale, isFreeShipping: isFreeShipping, isGroupOnly: isGroupOnly,
      rating: rating, reviewCount: reviewCount, stockCount: stockCount,
      isActive: isActive, createdAt: createdAt,
      sectionImages: newSectionImages,
      nameTranslations: nameTranslations,
      descriptionTranslations: descriptionTranslations,
    );
  }
}

class CartItem {
  final String id;
  final ProductModel product;
  String selectedSize;
  String selectedColor;
  int quantity;
  double extraPrice;          // 색상/옵션 추가금액
  Map<String, dynamic>? customOptions;

  CartItem({
    required this.id,
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
    this.extraPrice = 0,
    this.customOptions,
  });

  double get unitPrice  => product.price + extraPrice;   // 단품 가격
  double get totalPrice => unitPrice * quantity;          // 합계
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final double shippingFee;
  final String paymentMethod;
  final OrderStatus status;
  final String orderType; // personal, group, additional
  final Map<String, dynamic>? customOptions;
  final String? groupName;
  final int? groupCount;
  final DateTime createdAt;
  final String? memo;
  /// 추가제작 신청 횟수 (무제한)
  final int additionalOrderCount;
  /// 컬러+단체명 수정요청 사용 횟수 (최대 2회)
  final int colorEditCount;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    required this.userPhone,
    required this.userAddress,
    required this.items,
    required this.totalAmount,
    this.shippingFee = 0,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    this.orderType = 'personal',
    this.customOptions,
    this.groupName,
    this.groupCount,
    required this.createdAt,
    this.memo,
    this.additionalOrderCount = 0,
    this.colorEditCount = 0,
  });

  /// 컬러+단체명 수정 가능 여부 (총 2회)
  bool get canEditColor => colorEditCount < 2;
  /// 남은 컬러+단체명 수정 횟수
  int get remainingColorEdits => 2 - colorEditCount;

  OrderModel copyWith({
    OrderStatus? status,
    int? additionalOrderCount,
    int? colorEditCount,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      userAddress: userAddress,
      items: items,
      totalAmount: totalAmount,
      shippingFee: shippingFee,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      orderType: orderType,
      customOptions: customOptions,
      groupName: groupName,
      groupCount: groupCount,
      createdAt: createdAt,
      memo: memo,
      additionalOrderCount: additionalOrderCount ?? this.additionalOrderCount,
      colorEditCount: colorEditCount ?? this.colorEditCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'orderType': orderType,
      'customOptions': customOptions,
      'groupName': groupName,
      'groupCount': groupCount,
      'createdAt': createdAt.toIso8601String(),
      'memo': memo,
      'additionalOrderCount': additionalOrderCount,
      'colorEditCount': colorEditCount,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String size;
  final String color;
  final int quantity;
  final double price;
  final Map<String, dynamic>? customOptions;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.quantity,
    required this.price,
    this.customOptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'size': size,
      'color': color,
      'quantity': quantity,
      'price': price,
      'customOptions': customOptions,
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return '주문 대기';
      case OrderStatus.confirmed:
        return '주문 확인';
      case OrderStatus.processing:
        return '제작/준비 중';
      case OrderStatus.shipped:
        return '배송 중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.cancelled:
        return '주문 취소';
      case OrderStatus.refunded:
        return '환불 완료';
    }
  }
}

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final double rating;
  final String content;
  final List<String> images;
  final String size;
  final String color;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    required this.rating,
    required this.content,
    this.images = const [],
    required this.size,
    required this.color,
    required this.createdAt,
  });
}

// ── 쿠폰 모델 ────────────────────────────────────────
enum CouponType { fixed, percent }

class CouponModel {
  final String id;
  final String code;
  final String name;
  final CouponType type;
  final double value; // 금액 or 퍼센트
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final DateTime expiresAt;
  bool isUsed;

  CouponModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    this.minOrderAmount = 0,
    this.maxDiscountAmount,
    required this.expiresAt,
    this.isUsed = false,
  });

  bool get isValid =>
      !isUsed && expiresAt.isAfter(DateTime.now());

  double calculateDiscount(double orderAmount) {
    if (!isValid || orderAmount < minOrderAmount) return 0;
    if (type == CouponType.fixed) return value;
    final discount = orderAmount * value / 100;
    return maxDiscountAmount != null
        ? discount.clamp(0, maxDiscountAmount!)
        : discount;
  }

  String get typeLabel =>
      type == CouponType.fixed ? '${value.toInt()}원 할인' : '${value.toInt()}% 할인';
}

// ── 포인트 내역 모델 ──────────────────────────────────
enum PointActionType { earn, use, expire, refund }

class PointHistory {
  final String id;
  final PointActionType type;
  final int amount;
  final String description;
  final DateTime createdAt;

  PointHistory({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });
}

// ── 리뷰 작성 요청 모델 ──────────────────────────────
class ReviewWriteRequest {
  final String orderId;
  final String productId;
  final String productName;
  final double rating;
  final String content;
  final List<String> images;
  final String size;
  final String color;

  ReviewWriteRequest({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.content,
    this.images = const [],
    required this.size,
    required this.color,
  });
}

// 배송지 모델
class AddressModel {
  final String id;
  String label;       // 예: '집', '회사', '기타'
  String recipient;   // 수령인
  String phone;
  String zipCode;     // 우편번호
  String address1;    // 도로명/지번 주소
  String address2;    // 상세 주소
  bool isDefault;

  AddressModel({
    required this.id,
    this.label = '집',
    required this.recipient,
    required this.phone,
    this.zipCode = '',
    required this.address1,
    this.address2 = '',
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as String,
    label: json['label'] as String? ?? '집',
    recipient: json['recipient'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    zipCode: json['zipCode'] as String? ?? '',
    address1: json['address1'] as String? ?? '',
    address2: json['address2'] as String? ?? '',
    isDefault: json['isDefault'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'label': label, 'recipient': recipient, 'phone': phone,
    'zipCode': zipCode, 'address1': address1, 'address2': address2,
    'isDefault': isDefault,
  };
}

class UserModel {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  String profileImageUrl; // 프로필 이미지 URL (소셜 로그인 등)
  bool isAdmin;
  List<String> wishlist;
  int points;
  List<CouponModel> coupons;
  String memberTier; // bronze, silver, gold, vip
  String grade;      // memberTier 별칭 (하위 호환)
  DateTime createdAt;
  List<AddressModel> addresses; // 배송지 목록

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    this.profileImageUrl = '',
    this.isAdmin = false,
    this.wishlist = const [],
    this.points = 0,
    this.coupons = const [],
    this.memberTier = 'bronze',
    String? grade,
    required this.createdAt,
    this.addresses = const [],
  }) : grade = grade ?? memberTier;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final tier = json['memberTier'] as String? ?? json['grade'] as String? ?? 'bronze';
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      wishlist: List<String>.from(json['wishlist'] as List? ?? []),
      points: json['points'] as int? ?? 0,
      memberTier: tier,
      grade: tier,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now())
          : DateTime.now(),
      addresses: (json['addresses'] as List? ?? []).map((a) =>
        AddressModel.fromJson(Map<String, dynamic>.from(a as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'isAdmin': isAdmin,
      'wishlist': wishlist,
      'points': points,
      'memberTier': memberTier,
      'grade': memberTier,
      'createdAt': createdAt.toIso8601String(),
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }
  
  String get tierLabel {
    switch (memberTier) {
      case 'silver': return '실버';
      case 'gold': return '골드';
      case 'vip': return 'VIP';
      default: return '브론즈';
    }
  }
  
  Color get tierColor {
    switch (memberTier) {
      case 'silver': return const Color(0xFF9E9E9E);
      case 'gold': return const Color(0xFFFFB300);
      case 'vip': return const Color(0xFF6A1B9A);
      default: return const Color(0xFF795548);
    }
  }
}

// ── 인증 결과 ────────────────────────────────────────────
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}
