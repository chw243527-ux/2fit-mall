import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  /// 신상품 여부 (저장값) — 실제 노출은 [isNewActive] getter 사용
  final bool isNew;
  /// 신상품 자동 만료일 (null이면 무기한)
  final DateTime? newExpiresAt;
  final bool isSale;
  final bool isFreeShipping;
  final bool isGroupOnly;  // 단체주문 전용 상품
  final bool isReadyMade;  // 기성품 (단체주문에서 기성품 선택 가능)
  final double rating;
  final int reviewCount;
  final int stockCount;
  /// 사이즈별 품절 목록 (예: ['XL', '2XL']) — 해당 사이즈는 선택 불가
  final List<String> soldOutSizes;
  /// 실제 구매 완료된 누적 판매 수량 (confirmed 이상 주문 기준)
  final int salesCount;
  final bool isActive;
  final DateTime createdAt;
  // 관리자가 직접 입력하는 상품번호 (예: SA0001, TZ001)
  final String productCode;
  // 섹션별 관리자 업로드 이미지 (key: 's1','s2','s3','s4','s5','s6')
  final Map<String, List<String>> sectionImages;
  // 다국어 상품명 번역 (key: 'en','ja','zh','mn')
  final Map<String, String> nameTranslations;
  // 다국어 상품 설명 번역 (key: 'en','ja','zh','mn')
  final Map<String, String> descriptionTranslations;
  // 관리자 직접 입력 하의길이 (비어있으면 카테고리 기본값 자동 적용)
  final String bottomLength;
  /// 사이즈별 재고 수량 (예: {'S': 10, 'M': 20, 'L': 15})
  /// 비어있으면 stockCount를 전체 재고로 사용
  final Map<String, int> sizeStocks;

  /// 사이즈×색상별 재고 (예: {'M': {'Black': 10, 'White': 5}})
  /// inventory 컬렉션 대체 — products 문서에 직접 저장
  final Map<String, Map<String, int>> stockData;

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
    this.newExpiresAt,
    this.isSale = false,
    this.isFreeShipping = false,
    this.isGroupOnly = false,
    this.isReadyMade = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stockCount = 100,
    this.soldOutSizes = const [],
    this.salesCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.productCode = '',
    this.sectionImages = const {},
    this.nameTranslations = const {},
    this.descriptionTranslations = const {},
    this.bottomLength = '',
    this.sizeStocks = const {},
    this.stockData = const {},
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
      isNew: isNew, newExpiresAt: newExpiresAt,
      isSale: isSale, isFreeShipping: isFreeShipping,
      isGroupOnly: isGroupOnly, isReadyMade: isReadyMade,
      rating: rating, reviewCount: reviewCount,
      stockCount: stockCount, soldOutSizes: soldOutSizes,
      salesCount: salesCount, isActive: isActive, createdAt: createdAt,
      productCode: productCode,
      sectionImages: sectionImages,
      nameTranslations: nameTranslations ?? this.nameTranslations,
      descriptionTranslations: descriptionTranslations ?? this.descriptionTranslations,
      bottomLength: bottomLength,
      sizeStocks: sizeStocks,
      stockData: stockData,
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

  /// 신상품 뱃지 실제 노출 여부
  /// isNew=true 이고, 등록일(createdAt) 기준 60일이 지나지 않았을 때만 true
  /// newExpiresAt이 있으면 그 값 우선, 없으면 createdAt+60일로 자동 계산
  bool get isNewActive {
    if (!isNew) return false;
    final expiry = newExpiresAt ?? createdAt.add(const Duration(days: 60));
    return DateTime.now().isBefore(expiry);
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
      images: json['images'] != null ? List<String>.from(json['images'] as List) : const [],
      sizes: json['sizes'] != null ? List<String>.from(json['sizes'] as List) : const [],
      colors: json['colors'] != null ? List<String>.from(json['colors'] as List) : const [],
      material: json['material'] as String? ?? '78% Nylon, 22% Spandex',
      bottomLength: json['bottomLength'] as String? ?? '',
      isNew: json['isNew'] as bool? ?? false,
      newExpiresAt: json['newExpiresAt'] != null
          ? DateTime.tryParse(json['newExpiresAt'] as String)
          : null,
      isSale: json['isSale'] as bool? ?? false,
      isFreeShipping: json['isFreeShipping'] as bool? ?? false,
      isGroupOnly: json['isGroupOnly'] as bool? ?? false,
      isReadyMade: json['isReadyMade'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      stockCount: json['stockCount'] as int? ?? 100,
      soldOutSizes: (json['soldOutSizes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      sizeStocks: (json['sizeStocks'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
      stockData: () {
        final raw = json['stockData'] as Map<String, dynamic>?;
        if (raw == null) return const <String, Map<String, int>>{};
        return raw.map((size, colorRaw) {
          final colorMap = (colorRaw as Map<String, dynamic>)
              .map((c, q) => MapEntry(c, (q as num).toInt()));
          return MapEntry(size, colorMap);
        });
      }(),
      salesCount: json['salesCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      productCode: json['productCode'] as String? ?? '',
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
      'bottomLength': bottomLength,
      'isNew': isNew,
      'newExpiresAt': newExpiresAt?.toIso8601String(),
      'isSale': isSale,
      'isFreeShipping': isFreeShipping,
      'isGroupOnly': isGroupOnly,
      'isReadyMade': isReadyMade,
      'rating': rating,
      'reviewCount': reviewCount,
      'stockCount': stockCount,
      'soldOutSizes': soldOutSizes,
      'sizeStocks': sizeStocks,
      'stockData': stockData.map((size, colorMap) =>
          MapEntry(size, Map<String, dynamic>.from(colorMap))),
      'salesCount': salesCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'productCode': productCode,
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
      isNew: isNew, newExpiresAt: newExpiresAt,
      isSale: isSale, isFreeShipping: isFreeShipping,
      isGroupOnly: isGroupOnly, isReadyMade: isReadyMade,
      rating: rating, reviewCount: reviewCount, stockCount: stockCount,
      soldOutSizes: soldOutSizes,
      sizeStocks: sizeStocks,
      stockData: stockData,
      salesCount: salesCount,
      isActive: isActive, createdAt: createdAt,
      productCode: productCode,
      sectionImages: newSectionImages,
      nameTranslations: nameTranslations,
      descriptionTranslations: descriptionTranslations,
      bottomLength: bottomLength,
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
  /// 디자인 수정 요청 횟수 (최대 2회)
  final int designRevisionCount;
  /// 디자인 수정 요청 마감일 (요청 후 3일, null이면 요청 없음)
  final DateTime? designRevisionDeadline;
  /// 배송완료 날짜 (자동 구매확정 기준)
  final DateTime? deliveredAt;
  /// 결제 키 (토스페이먼츠 paymentKey — 영수증 조회용)
  final String? paymentKey;
  /// 현금영수증 번호 (전화번호 or 사업자번호)
  final String? cashReceiptNum;
  /// 추가제작 가능 마감일 (주문완료 후 7일)
  DateTime get additionalOrderDeadline => createdAt.add(const Duration(days: 7));
  /// 추가제작 무료 가능 여부
  bool get canOrderAdditionalFree => DateTime.now().isBefore(additionalOrderDeadline);

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
    this.designRevisionCount = 0,
    this.designRevisionDeadline,
    this.deliveredAt,
    this.paymentKey,
    this.cashReceiptNum,
  });

  /// 자동 구매확정 여부 (배송완료 후 3일 경과)
  bool get isAutoConfirmDue {
    if (status != OrderStatus.delivered) return false;
    if (deliveredAt == null) {
      // deliveredAt 없으면 updatedAt 기준으로 폴백
      return false;
    }
    return DateTime.now().isAfter(deliveredAt!.add(const Duration(days: 3)));
  }

  /// 구매확정 여부 (수동 or 자동)
  bool get isPurchaseConfirmed =>
      status == OrderStatus.purchaseConfirmed || isAutoConfirmDue;

  /// 컬러+단체명 수정 가능 여부 (총 2회)
  bool get canEditColor => colorEditCount < 2;
  /// 남은 컬러+단체명 수정 횟수
  int get remainingColorEdits => 2 - colorEditCount;
  /// 디자인 수정 가능 여부 (총 2회, 마감일 이내)
  bool get canDesignRevision => designRevisionCount < 2;
  /// 남은 디자인 수정 횟수
  int get remainingDesignRevisions => 2 - designRevisionCount;

  /// 디자인수정요청 기간 내 여부 (confirmed 후 3일 이내, designRevisionDeadline 기준)
  /// designRevisionDeadline이 null이면 기간 미설정 → 요청 가능으로 처리
  bool get isDesignRevisionPeriodActive {
    if (designRevisionDeadline == null) return true;
    return DateTime.now().isBefore(designRevisionDeadline!);
  }

  /// 단체주문 디자인수정요청 가능 여부 (주문대기/확인/제작중 상태 + 2회 미만 + 기간 이내)
  bool get canRequestDesignRevision =>
      (status == OrderStatus.pending ||
       status == OrderStatus.confirmed ||
       status == OrderStatus.processing) &&
      canDesignRevision &&
      isDesignRevisionPeriodActive;

  /// 디자인 확정 여부 (3일 경과 후 수정 요청 없음 or 제작 완료 이상)
  bool get isDesignConfirmed =>
      (designRevisionDeadline != null && DateTime.now().isAfter(designRevisionDeadline!)) ||
      (status == OrderStatus.shipped || status == OrderStatus.delivered ||
       status == OrderStatus.purchaseConfirmed);

  /// 관리자가 업로드한 수정 완료 디자인 이미지 URL
  /// customOptions['designConfirmedImageUrl'] 에 저장됨
  String? get designConfirmedImageUrl =>
      customOptions?['designConfirmedImageUrl'] as String?;

  /// 디자인 수정 요청 맵 (customOptions['designRevisionRequest'])
  Map<String, dynamic>? get designRevisionRequest =>
      customOptions?['designRevisionRequest'] as Map<String, dynamic>?;

  /// 관리자 응답 여부 (designRevisionRequest.status == 'responded')
  bool get isDesignRevisionResponded =>
      designRevisionRequest?['status'] == 'responded';

  /// 사용자가 수정 완료 디자인을 확정했는지 여부
  /// customOptions['userDesignApproved'] == true 일 때 제작 시작 상태
  bool get userDesignApproved =>
      customOptions?['userDesignApproved'] == true;

  OrderModel copyWith({
    OrderStatus? status,
    int? additionalOrderCount,
    int? colorEditCount,
    int? designRevisionCount,
    DateTime? designRevisionDeadline,
    DateTime? deliveredAt,
    String? paymentKey,
    String? cashReceiptNum,
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
      designRevisionCount: designRevisionCount ?? this.designRevisionCount,
      designRevisionDeadline: designRevisionDeadline ?? this.designRevisionDeadline,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      paymentKey: paymentKey ?? this.paymentKey,
      cashReceiptNum: cashReceiptNum ?? this.cashReceiptNum,
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
      'designRevisionCount': designRevisionCount,
      'designRevisionDeadline': designRevisionDeadline?.toIso8601String(),
      if (paymentKey != null) 'paymentKey': paymentKey,
      if (cashReceiptNum != null) 'cashReceiptNum': cashReceiptNum,
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
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.quantity,
    required this.price,
    this.customOptions,
    this.imageUrl,
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
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  purchaseConfirmed,
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
      case OrderStatus.purchaseConfirmed:
        return '구매 확정';
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
  String loginProvider; // email, google, kakao, naver
  String? cashReceiptNum; // 현금영수증 번호 (전화번호 or 사업자번호)

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
    this.loginProvider = 'email',
    this.cashReceiptNum,
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
      loginProvider: json['loginProvider'] as String? ?? 'email',
      cashReceiptNum: json['cashReceiptNum'] as String?,
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
      'loginProvider': loginProvider,
      if (cashReceiptNum != null && cashReceiptNum!.isNotEmpty)
        'cashReceiptNum': cashReceiptNum,
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

// ── 사이즈 프로필 ────────────────────────────────────────
class SizeProfile {
  final String id;          // Firestore 문서 ID
  final String userId;      // 소유 유저 ID
  String profileName;       // 프로필 이름 (예: "내 기본 사이즈", "겨울 오버핏")
  String gender;            // 'male' | 'female'
  String sizeType;          // '성인' | '주니어'
  String topSize;           // 상의 사이즈
  String bottomSize;        // 하의 사이즈
  String height;            // 키
  String weight;            // 몸무게
  String waist;             // 허리
  String thigh;             // 허벅지
  DateTime updatedAt;

  SizeProfile({
    required this.id,
    required this.userId,
    required this.profileName,
    required this.gender,
    this.sizeType = '성인',
    required this.topSize,
    required this.bottomSize,
    this.height = '',
    this.weight = '',
    this.waist = '',
    this.thigh = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory SizeProfile.fromJson(String docId, Map<String, dynamic> json) {
    return SizeProfile(
      id: docId,
      userId: json['userId'] as String? ?? '',
      profileName: json['profileName'] as String? ?? '내 사이즈',
      gender: json['gender'] as String? ?? 'male',
      sizeType: json['sizeType'] as String? ?? '성인',
      topSize: json['topSize'] as String? ?? '',
      bottomSize: json['bottomSize'] as String? ?? '',
      height: json['height'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      waist: json['waist'] as String? ?? '',
      thigh: json['thigh'] as String? ?? '',
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'profileName': profileName,
    'gender': gender,
    'sizeType': sizeType,
    'topSize': topSize,
    'bottomSize': bottomSize,
    'height': height,
    'weight': weight,
    'waist': waist,
    'thigh': thigh,
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get genderLabel => gender == 'male' ? '남성' : '여성';
}

// ── 날짜 파싱 헬퍼 ────────────────────────────────────────
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  // Firestore Timestamp 처리
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}

// ── 홈 배너 ────────────────────────────────────────────
/// Firestore /banners/{id} 문서 구조
class BannerModel {
  final String id;
  final int order;          // 표시 순서 (0부터)
  final bool active;        // 노출 여부
  final String title;       // 배너 제목 (관리자 표시용)
  final String tag;         // 태그 뱃지 텍스트
  final String titleKo;     // 슬라이드 메인 타이틀 (한국어)
  final String titleEn;     // 슬라이드 메인 타이틀 (영어)
  final String ctaKo;       // CTA 버튼 텍스트 (한국어)
  final String ctaEn;       // CTA 버튼 텍스트 (영어)
  final String imageUrl;    // 배경 이미지 URL (Firebase Storage)
  final String? videoUrl;   // 동영상 URL (1번 슬라이드 전용, null이면 이미지)
  final int accentColor;    // accent 색상 (ARGB int)
  final int btnAction;      // 0=신상, 1=베스트, 2=단체주문
  final DateTime? startDate; // 노출 시작일 (null=제한없음)
  final DateTime? endDate;   // 노출 종료일 (null=제한없음)

  const BannerModel({
    required this.id,
    required this.order,
    this.active = true,
    required this.title,
    this.tag = '',
    this.titleKo = '',
    this.titleEn = '',
    this.ctaKo = '',
    this.ctaEn = '',
    this.imageUrl = '',
    this.videoUrl,
    this.accentColor = 0xFFE53935,
    this.btnAction = 0,
    this.startDate,
    this.endDate,
  });

  /// 현재 시각 기준 기간 내 노출 여부
  bool get isInSchedule {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate   != null && now.isAfter(endDate!))    return false;
    return true;
  }

  factory BannerModel.fromFirestore(Map<String, dynamic> d, String id) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }
    return BannerModel(
      id: id,
      order: (d['order'] as num?)?.toInt() ?? 99,
      active: (d['active'] as bool?) ?? true,
      title: (d['title'] as String?) ?? '',
      tag: (d['tag'] as String?) ?? '',
      titleKo: (d['titleKo'] as String?) ?? '',
      titleEn: (d['titleEn'] as String?) ?? '',
      ctaKo: (d['ctaKo'] as String?) ?? '',
      ctaEn: (d['ctaEn'] as String?) ?? '',
      imageUrl: (d['imageUrl'] as String?) ?? '',
      videoUrl: d['videoUrl'] as String?,
      accentColor: (d['accentColor'] as num?)?.toInt() ?? 0xFFE53935,
      btnAction: (d['btnAction'] as num?)?.toInt() ?? 0,
      startDate: _parseDate(d['startDate']),
      endDate:   _parseDate(d['endDate']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'order': order,
    'active': active,
    'title': title,
    'tag': tag,
    'titleKo': titleKo,
    'titleEn': titleEn,
    'ctaKo': ctaKo,
    'ctaEn': ctaEn,
    'imageUrl': imageUrl,
    if (videoUrl != null && videoUrl!.isNotEmpty) 'videoUrl': videoUrl,
    'accentColor': accentColor,
    'btnAction': btnAction,
    if (startDate != null) 'startDate': Timestamp.fromDate(startDate!)
    else 'startDate': null,
    if (endDate != null)   'endDate':   Timestamp.fromDate(endDate!)
    else 'endDate': null,
  };

  BannerModel copyWith({
    String? id, int? order, bool? active, String? title, String? tag,
    String? titleKo, String? titleEn, String? ctaKo, String? ctaEn,
    String? imageUrl, String? videoUrl, int? accentColor, int? btnAction,
    Object? startDate = _sentinel, Object? endDate = _sentinel,
  }) => BannerModel(
    id: id ?? this.id,
    order: order ?? this.order,
    active: active ?? this.active,
    title: title ?? this.title,
    tag: tag ?? this.tag,
    titleKo: titleKo ?? this.titleKo,
    titleEn: titleEn ?? this.titleEn,
    ctaKo: ctaKo ?? this.ctaKo,
    ctaEn: ctaEn ?? this.ctaEn,
    imageUrl: imageUrl ?? this.imageUrl,
    videoUrl: videoUrl ?? this.videoUrl,
    accentColor: accentColor ?? this.accentColor,
    btnAction: btnAction ?? this.btnAction,
    startDate: startDate == _sentinel ? this.startDate : startDate as DateTime?,
    endDate:   endDate   == _sentinel ? this.endDate   : endDate   as DateTime?,
  );
}

const Object _sentinel = Object();

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

// ════════════════════════════════════════════════════════════
//  재고 관리 모델
// ════════════════════════════════════════════════════════════

/// 입출고 유형
enum InventoryLogType {
  incoming,   // 입고
  outgoing,   // 출고
  adjustment, // 재고조정
  reorder,    // 발주
}

extension InventoryLogTypeExt on InventoryLogType {
  String get label {
    switch (this) {
      case InventoryLogType.incoming:   return '입고';
      case InventoryLogType.outgoing:   return '출고';
      case InventoryLogType.adjustment: return '재고조정';
      case InventoryLogType.reorder:    return '발주';
    }
  }
  String get value {
    switch (this) {
      case InventoryLogType.incoming:   return 'incoming';
      case InventoryLogType.outgoing:   return 'outgoing';
      case InventoryLogType.adjustment: return 'adjustment';
      case InventoryLogType.reorder:    return 'reorder';
    }
  }
  static InventoryLogType fromString(String v) {
    switch (v) {
      case 'incoming':   return InventoryLogType.incoming;
      case 'outgoing':   return InventoryLogType.outgoing;
      case 'adjustment': return InventoryLogType.adjustment;
      case 'reorder':    return InventoryLogType.reorder;
      default:           return InventoryLogType.incoming;
    }
  }
}

/// 사이즈별 재고 현황 (Firestore: inventory/{productId})
class InventoryModel {
  final String productId;
  final String productName;
  final String productCode; // 바코드용 코드
  final String imageUrl;    // 대표 이미지 URL
  /// 사이즈 → 색상 → 수량  예: {'S': {'블랙': 10, '화이트': 5}}
  final Map<String, Map<String, int>> stock;
  final int reorderPoint;   // 발주 기준 수량 (이하이면 경고)
  final DateTime updatedAt;

  const InventoryModel({
    required this.productId,
    required this.productName,
    required this.productCode,
    this.imageUrl = '',
    required this.stock,
    this.reorderPoint = 5,
    required this.updatedAt,
  });

  /// 전체 재고 합산
  int get totalStock => stock.values
      .expand((colorMap) => colorMap.values)
      .fold(0, (sum, qty) => sum + qty);

  /// 특정 사이즈 전체 재고
  int stockForSize(String size) =>
      (stock[size] ?? {}).values.fold(0, (s, v) => s + v);

  /// 특정 사이즈+색상 재고
  int stockForSizeColor(String size, String color) =>
      stock[size]?[color] ?? 0;

  bool get needsReorder => totalStock <= reorderPoint;

  InventoryModel copyWith({
    Map<String, Map<String, int>>? stock,
    int? reorderPoint,
    DateTime? updatedAt,
    String? imageUrl,
  }) => InventoryModel(
    productId:   productId,
    productName: productName,
    productCode: productCode,
    imageUrl:    imageUrl    ?? this.imageUrl,
    stock:        stock        ?? this.stock,
    reorderPoint: reorderPoint ?? this.reorderPoint,
    updatedAt:    updatedAt    ?? this.updatedAt,
  );

  factory InventoryModel.fromJson(String id, Map<String, dynamic> json) {
    final rawStock = json['stock'] as Map<String, dynamic>? ?? {};
    final stock = rawStock.map((size, colorRaw) {
      final colorMap = (colorRaw as Map<String, dynamic>).map(
        (color, qty) => MapEntry(color, (qty as num).toInt()),
      );
      return MapEntry(size, colorMap);
    });
    return InventoryModel(
      productId:   id,
      productName: json['productName'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      stock:        stock,
      reorderPoint: json['reorderPoint'] as int? ?? 5,
      updatedAt:    (json['updatedAt'] != null)
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'productCode': productCode,
    'stock': stock.map((size, colorMap) =>
        MapEntry(size, colorMap.map((c, q) => MapEntry(c, q)))),
    'reorderPoint': reorderPoint,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// 입출고 이력 (Firestore: inventory_logs/)
class InventoryLog {
  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final String size;
  final String color;
  final InventoryLogType type;
  final int quantity;       // 변경 수량 (항상 양수)
  final int beforeQty;      // 변경 전 재고
  final int afterQty;       // 변경 후 재고
  final String memo;
  final String adminId;
  final DateTime createdAt;

  const InventoryLog({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.size,
    required this.color,
    required this.type,
    required this.quantity,
    required this.beforeQty,
    required this.afterQty,
    this.memo = '',
    required this.adminId,
    required this.createdAt,
  });

  factory InventoryLog.fromJson(String id, Map<String, dynamic> json) =>
      InventoryLog(
        id:          id,
        productId:   json['productId']   as String? ?? '',
        productName: json['productName'] as String? ?? '',
        productCode: json['productCode'] as String? ?? '',
        size:        json['size']        as String? ?? '',
        color:       json['color']       as String? ?? '',
        type:        InventoryLogTypeExt.fromString(json['type'] as String? ?? ''),
        quantity:    json['quantity']    as int? ?? 0,
        beforeQty:   json['beforeQty']   as int? ?? 0,
        afterQty:    json['afterQty']    as int? ?? 0,
        memo:        json['memo']        as String? ?? '',
        adminId:     json['adminId']     as String? ?? '',
        createdAt:   (json['createdAt'] != null)
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'productId':   productId,
    'productName': productName,
    'productCode': productCode,
    'size':        size,
    'color':       color,
    'type':        type.value,
    'quantity':    quantity,
    'beforeQty':   beforeQty,
    'afterQty':    afterQty,
    'memo':        memo,
    'adminId':     adminId,
    'createdAt':   createdAt.toIso8601String(),
  };
}
