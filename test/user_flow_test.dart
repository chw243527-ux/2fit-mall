/// ============================================================
/// 실제 사용자 흐름 통합 테스트 (2FIT Mall)
/// Run: flutter test test/user_flow_test.dart --no-pub
/// ============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:twofit_mall/models/models.dart';

// ── 헬퍼: 금액 포맷 ──
String fmtAmt(double v) =>
    '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원';

// ── 헬퍼: 주문 ID 생성 ──
String _genId() {
  final now = DateTime.now();
  final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final seq = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
  return 'ORD-$ts-$seq';
}

// ── 헬퍼: 사용자 생성 ──
UserModel makeUser({
  String id = 'user_001',
  String name = '최혜원',
  String email = 'tbrk2435@naver.com',
  String phone = '010-7227-6914',
  List<String>? wishlist,
  int points = 0,
}) =>
    UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      address: '전북특별자치도 남원시 역재2길 14-5',
      wishlist: wishlist ?? [],
      points: points,
      createdAt: DateTime.now(),
    );

// ── 헬퍼: 상품 생성 ──
ProductModel makeProduct({
  String id = 'p001',
  String name = '2FIT 라운드넥 티셔츠',
  double price = 35000,
}) =>
    ProductModel(
      id: id,
      name: name,
      category: '상의',
      price: price,
      originalPrice: price * 1.2,
      description: '테스트 상품',
      images: ['https://example.com/img.jpg'],
      sizes: ['S', 'M', 'L', 'XL'],
      colors: ['Black', 'White', 'Navy'],
      isNew: false,
      isSale: false,
      isFreeShipping: true,
      rating: 4.5,
      reviewCount: 10,
      stockCount: 100,
      createdAt: DateTime.now(),
    );

// ── 헬퍼: CartItem 생성 (실제 필드명 사용) ──
CartItem makeCartItem({
  String? id,
  ProductModel? product,
  String size = 'M',
  String color = 'Black',
  int quantity = 1,
  double extraPrice = 0,
}) {
  final p = product ?? makeProduct();
  return CartItem(
    id: id ?? 'cart_${p.id}_${size}_$color',
    product: p,
    selectedSize: size,
    selectedColor: color,
    quantity: quantity,
    extraPrice: extraPrice,
  );
}

// ── 헬퍼: OrderItem 생성 ──
OrderItem makeOrderItem({
  String productId = 'p001',
  String productName = '2FIT 라운드넥 티셔츠',
  String size = 'M',
  String color = 'Black',
  int quantity = 2,
  double price = 35000,
  String? imageUrl,
}) =>
    OrderItem(
      productId: productId,
      productName: productName,
      size: size,
      color: color,
      quantity: quantity,
      price: price,
      imageUrl: imageUrl,
    );

// ── 헬퍼: AddressModel 생성 (실제 필드명: recipient, address1) ──
AddressModel makeAddress({
  String id = 'addr_001',
  String label = '집',
  String recipient = '최혜원',
  String phone = '010-7227-6914',
  String zipCode = '55715',
  String address1 = '전북특별자치도 남원시 역재2길 14-5',
  String address2 = '1층',
  bool isDefault = true,
}) =>
    AddressModel(
      id: id,
      label: label,
      recipient: recipient,
      phone: phone,
      zipCode: zipCode,
      address1: address1,
      address2: address2,
      isDefault: isDefault,
    );

// ── 헬퍼: CouponModel 생성 (createdAt 없음) ──
CouponModel makeCoupon({
  String id = 'c001',
  String code = 'WELCOME10',
  String name = '신규가입 10% 할인',
  CouponType type = CouponType.percent,
  double value = 10,
  double minOrderAmount = 20000,
  bool isUsed = false,
  bool isStackable = false,
  DateTime? expiresAt,
}) =>
    CouponModel(
      id: id,
      code: code,
      name: name,
      type: type,
      value: value,
      minOrderAmount: minOrderAmount,
      isUsed: isUsed,
      isStackable: isStackable,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
    );

// ── 헬퍼: 개인 주문 생성 ──
OrderModel makePersonalOrder({
  String? id,
  String userId = 'user_001',
  List<OrderItem>? items,
  double? totalAmount,
  OrderStatus status = OrderStatus.pending,
  DateTime? createdAt,
}) {
  final oi = items ?? [makeOrderItem()];
  final amt = totalAmount ??
      oi.fold<double>(0.0, (s, i) => s + i.price * i.quantity);
  return OrderModel(
    id: id ?? _genId(),
    userId: userId,
    userName: '최혜원',
    userEmail: 'tbrk2435@naver.com',
    userPhone: '010-7227-6914',
    userAddress: '전북특별자치도 남원시 역재2길 14-5',
    items: oi,
    totalAmount: amt,
    shippingFee: 0,
    paymentMethod: '무통장입금',
    status: status,
    orderType: 'personal',
    createdAt: createdAt ?? DateTime.now(),
  );
}

// ── 헬퍼: 단체 주문 생성 ──
OrderModel makeGroupOrder({
  String? id,
  String userId = 'user_001',
  String groupName = '남원FC',
  int groupCount = 22,
  double totalAmount = 770000,
  OrderStatus status = OrderStatus.pending,
  List<OrderItem>? items,
  DateTime? createdAt,
}) =>
    OrderModel(
      id: id ?? 'GRP_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: '최혜원',
      userEmail: 'tbrk2435@naver.com',
      userPhone: '010-7227-6914',
      userAddress: '전북특별자치도 남원시 역재2길 14-5',
      items: items ?? [],
      totalAmount: totalAmount,
      shippingFee: 0,
      paymentMethod: '무통장입금',
      status: status,
      orderType: 'group',
      groupName: groupName,
      groupCount: groupCount,
      createdAt: createdAt ?? DateTime.now(),
    );

void main() {
  // ────────────────────────────────────────────
  group('📦 상품 모델', () {
    test('상품 생성 및 기본 필드 검증', () {
      final p = makeProduct();
      expect(p.id, 'p001');
      expect(p.name, '2FIT 라운드넥 티셔츠');
      expect(p.price, 35000.0);
      expect(p.sizes, contains('M'));
      expect(p.colors, contains('Black'));
      expect(p.stockCount, greaterThan(0));
      print('  ✅ [${p.id}] ${p.name} — ${fmtAmt(p.price)}');
    });

    test('할인율 계산', () {
      final p = makeProduct(price: 35000);
      final originalPrice = p.originalPrice ?? p.price;
      final rate = originalPrice > 0
          ? ((originalPrice - p.price) / originalPrice * 100).round()
          : 0;
      expect(rate, greaterThanOrEqualTo(0));
      print('  ✅ 할인율 $rate% (원가 ${fmtAmt(originalPrice)} → ${fmtAmt(p.price)})');
    });

    test('상품 카탈로그 4종', () {
      final catalog = [
        makeProduct(id: 'p001', name: '2FIT 라운드넥 티셔츠', price: 35000),
        makeProduct(id: 'p002', name: '2FIT 크롭 탑', price: 28000),
        makeProduct(id: 'p003', name: '2FIT 조거 팬츠', price: 52000),
        makeProduct(id: 'p004', name: '2FIT 후드 집업', price: 68000),
      ];
      expect(catalog.length, 4);
      final totalValue = catalog.fold(0.0, (s, p) => s + p.price);
      print('  ✅ 카탈로그 ${catalog.length}종 총가치: ${fmtAmt(totalValue)}');
      for (final p in catalog) {
        print('     • [${p.id}] ${p.name} — ${fmtAmt(p.price)}');
      }
    });
  });

  // ────────────────────────────────────────────
  group('🛒 장바구니 (CartItem)', () {
    test('CartItem 생성 및 totalPrice', () {
      final item = makeCartItem(size: 'L', color: 'Navy', quantity: 3);
      expect(item.selectedSize, 'L');
      expect(item.selectedColor, 'Navy');
      expect(item.quantity, 3);
      expect(item.totalPrice, item.product.price * 3);
      print('  ✅ 장바구니: ${item.product.name} / ${item.selectedColor} / ${item.selectedSize} ×${item.quantity} = ${fmtAmt(item.totalPrice)}');
    });

    test('다수 CartItem 합산', () {
      final cart = [
        makeCartItem(product: makeProduct(id: 'p001', price: 35000), size: 'M', color: 'Black', quantity: 2),
        makeCartItem(product: makeProduct(id: 'p002', name: '크롭탑', price: 28000), size: 'S', color: 'White', quantity: 1),
        makeCartItem(product: makeProduct(id: 'p003', name: '팬츠', price: 52000), size: 'L', color: 'Gray', quantity: 1),
      ];
      final total = cart.fold(0.0, (s, c) => s + c.totalPrice);
      expect(total, 35000 * 2 + 28000 + 52000);
      print('  ✅ 장바구니 ${cart.length}종 — 합계: ${fmtAmt(total)}');
      for (final c in cart) {
        print('     • ${c.product.name} ×${c.quantity} = ${fmtAmt(c.totalPrice)}');
      }
    });

    test('옵션 추가금액 적용', () {
      final item = makeCartItem(quantity: 2, extraPrice: 2000);
      expect(item.unitPrice, 37000);
      expect(item.totalPrice, 74000);
      print('  ✅ 기본가 ${fmtAmt(item.product.price)} + 추가 ${fmtAmt(item.extraPrice)} = 단가 ${fmtAmt(item.unitPrice)} ×${item.quantity} = ${fmtAmt(item.totalPrice)}');
    });
  });

  // ────────────────────────────────────────────
  group('🧾 주문 생성', () {
    test('단일 상품 개인 주문', () {
      final order = makePersonalOrder(items: [makeOrderItem(quantity: 1, price: 35000)]);
      expect(order.orderType, 'personal');
      expect(order.totalAmount, 35000);
      expect(order.status, OrderStatus.pending);
      expect(order.id, matches(RegExp(r'^ORD-\d{8}-\d{5}$')));
      print('  ✅ 주문 ${order.id} — ${fmtAmt(order.totalAmount)} [${order.status.label}]');
    });

    test('다품목 주문 금액 합산', () {
      final items = [
        makeOrderItem(productId: 'p001', quantity: 2, price: 35000),
        makeOrderItem(productId: 'p002', productName: '크롭탑', size: 'S', color: 'White', quantity: 1, price: 28000),
        makeOrderItem(productId: 'p003', productName: '팬츠', size: 'L', color: 'Gray', quantity: 1, price: 52000),
      ];
      final expected = 35000 * 2 + 28000 + 52000;
      final order = makePersonalOrder(items: items, totalAmount: expected.toDouble());
      expect(order.items.length, 3);
      expect(order.totalAmount, expected.toDouble());
      print('  ✅ 3종 주문 — 합계: ${fmtAmt(order.totalAmount)}');
      for (final i in order.items) {
        print('     • ${i.productName} / ${i.color} / ${i.size} ×${i.quantity} = ${fmtAmt(i.price * i.quantity)}');
      }
    });

    test('OrderItem JSON 직렬화', () {
      final item = makeOrderItem(quantity: 2, price: 35000);
      final json = item.toJson();
      expect(json['productId'], 'p001');
      expect(json['size'], 'M');
      expect(json['color'], 'Black');
      expect(json['quantity'], 2);
      expect(json['price'], 35000.0);
      print('  ✅ OrderItem JSON: ${json['productName']} / ${json['color']} / ${json['size']} ×${json['quantity']}');
    });

    test('주문 JSON 직렬화', () {
      final order = makePersonalOrder();
      final json = order.toJson();
      expect(json['userId'], 'user_001');
      expect(json['status'], 'pending');
      expect(json['orderType'], 'personal');
      expect(json['items'], isList);
      print('  ✅ OrderModel JSON: id=${json['id']}, status=${json['status']}');
    });
  });

  // ────────────────────────────────────────────
  group('📊 주문 상태 흐름', () {
    test('모든 상태 라벨 검증', () {
      final expected = {
        OrderStatus.pending: '주문 대기',
        OrderStatus.confirmed: '주문 확인',
        OrderStatus.processing: '제작/준비 중',
        OrderStatus.shipped: '배송 중',
        OrderStatus.delivered: '배송 완료',
        OrderStatus.cancelled: '주문 취소',
        OrderStatus.refunded: '환불 완료',
      };
      for (final e in expected.entries) {
        expect(e.key.label, e.value);
        print('  ✅ ${e.key.name} → "${e.value}"');
      }
    });

    test('주문→배송완료 전체 흐름 (copyWith)', () {
      var order = makePersonalOrder();
      final flow = [
        OrderStatus.confirmed,
        OrderStatus.processing,
        OrderStatus.shipped,
        OrderStatus.delivered,
      ];
      print('  ✅ 상태 흐름: ${order.status.label}');
      for (final s in flow) {
        order = order.copyWith(status: s);
        expect(order.status, s);
        print('     → ${order.status.label}');
      }
    });

    test('취소 가능 여부 판단', () {
      final canCancel = [OrderStatus.pending, OrderStatus.confirmed];
      final cannotCancel = [OrderStatus.processing, OrderStatus.shipped, OrderStatus.delivered];
      for (final s in canCancel) {
        expect(s == OrderStatus.pending || s == OrderStatus.confirmed, isTrue);
        print('  ✅ ${s.label} → 취소 가능');
      }
      for (final s in cannotCancel) {
        expect(s == OrderStatus.pending || s == OrderStatus.confirmed, isFalse);
        print('  ✅ ${s.label} → 취소 불가');
      }
    });
  });

  // ────────────────────────────────────────────
  group('👥 단체주문', () {
    test('단체주문 생성', () {
      final order = makeGroupOrder(groupName: '남원FC', groupCount: 22, totalAmount: 770000);
      expect(order.orderType, 'group');
      expect(order.groupName, '남원FC');
      expect(order.groupCount, 22);
      expect(order.totalAmount, 770000);
      print('  ✅ 단체주문: ${order.groupName} ${order.groupCount}벌 — ${fmtAmt(order.totalAmount)}');
    });

    test('추가제작 마감일 (7일)', () {
      final recent = makeGroupOrder(createdAt: DateTime.now().subtract(const Duration(days: 3)));
      final old = makeGroupOrder(createdAt: DateTime.now().subtract(const Duration(days: 10)));
      expect(recent.canOrderAdditionalFree, isTrue);
      expect(old.canOrderAdditionalFree, isFalse);
      print('  ✅ 3일 전 주문 → 추가제작 가능 / 10일 전 주문 → 불가');
    });

    test('컬러 수정 횟수 제한 (최대 2회)', () {
      var order = makeGroupOrder();
      expect(order.canEditColor, isTrue);
      expect(order.remainingColorEdits, 2);

      order = order.copyWith(colorEditCount: 1);
      expect(order.canEditColor, isTrue);
      expect(order.remainingColorEdits, 1);

      order = order.copyWith(colorEditCount: 2);
      expect(order.canEditColor, isFalse);
      expect(order.remainingColorEdits, 0);
      print('  ✅ 컬러수정: 0회(가능) → 1회(1회남음) → 2회(불가)');
    });

    test('디자인 수정 횟수 제한 (최대 2회)', () {
      var order = makeGroupOrder();
      expect(order.canDesignRevision, isTrue);
      order = order.copyWith(designRevisionCount: 2);
      expect(order.canDesignRevision, isFalse);
      print('  ✅ 디자인수정: 0회→가능 / 2회→불가');
    });

    test('items 없는 단체주문 (상세 화면 fallback)', () {
      final order = makeGroupOrder(items: []);
      expect(order.items.isEmpty, isTrue);
      expect(order.groupName, isNotNull);
      expect(order.groupCount, isNotNull);
      // fallback: groupName + groupCount + totalAmount 표시 검증
      final displayName = order.groupName!.isNotEmpty ? order.groupName! : '단체주문';
      expect(displayName, '남원FC');
      print('  ✅ items 없는 단체주문 → fallback: "$displayName" ${order.groupCount}벌 ${fmtAmt(order.totalAmount)}');
    });
  });

  // ────────────────────────────────────────────
  group('❤️ 찜 (Wishlist)', () {
    test('찜 추가', () {
      final user = makeUser(wishlist: []);
      user.wishlist.add('p001');
      expect(user.wishlist, contains('p001'));
      print('  ✅ 찜 추가: p001 (총 ${user.wishlist.length}개)');
    });

    test('찜 토글 (제거 후 추가)', () {
      final user = makeUser(wishlist: ['p001', 'p002']);
      user.wishlist.remove('p001');
      expect(user.wishlist, isNot(contains('p001')));
      user.wishlist.add('p003');
      expect(user.wishlist, contains('p003'));
      expect(user.wishlist.length, 2);
      print('  ✅ 찜: p001 제거 + p003 추가 → ${user.wishlist}');
    });

    test('중복 찜 방지', () {
      final user = makeUser(wishlist: ['p001']);
      if (!user.wishlist.contains('p001')) user.wishlist.add('p001');
      expect(user.wishlist.where((id) => id == 'p001').length, 1);
      print('  ✅ 중복 방지: p001은 1개만 유지');
    });
  });

  // ────────────────────────────────────────────
  group('🎟️ 쿠폰', () {
    test('정률 쿠폰 10% 할인', () {
      final coupon = makeCoupon(type: CouponType.percent, value: 10);
      final amt = 50000.0;
      final discount = coupon.calculateDiscount(amt);
      expect(discount, 5000.0);
      print('  ✅ 10% 쿠폰: ${fmtAmt(amt)} → 할인 ${fmtAmt(discount)} → 최종 ${fmtAmt(amt - discount)}');
    });

    test('정액 쿠폰 3,000원 할인', () {
      final coupon = makeCoupon(type: CouponType.fixed, value: 3000, code: 'FIXED3K', name: '3,000원 할인');
      final amt = 50000.0;
      final discount = coupon.calculateDiscount(amt);
      expect(discount, 3000.0);
      print('  ✅ 정액 쿠폰: ${fmtAmt(amt)} → 할인 ${fmtAmt(discount)} → 최종 ${fmtAmt(amt - discount)}');
    });

    test('최소주문금액 미달 시 할인 0원', () {
      final coupon = makeCoupon(minOrderAmount: 30000);
      final discount = coupon.calculateDiscount(20000);
      expect(discount, 0.0);
      print('  ✅ 최소금액(${fmtAmt(30000)}) 미달 → 할인 없음');
    });

    test('만료 쿠폰 isValid = false', () {
      final expired = makeCoupon(expiresAt: DateTime.now().subtract(const Duration(days: 1)));
      expect(expired.isValid, isFalse);
      expect(expired.calculateDiscount(50000), 0.0);
      print('  ✅ 만료 쿠폰 → 사용 불가 (할인 0원)');
    });

    test('사용된 쿠폰 isValid = false', () {
      final used = makeCoupon(isUsed: true);
      expect(used.isValid, isFalse);
      print('  ✅ 사용된 쿠폰 → 사용 불가');
    });

    test('최대 할인금액 상한선', () {
      final coupon = CouponModel(
        id: 'c_max', code: 'MAX20', name: '20% (최대 5,000원)',
        type: CouponType.percent, value: 20,
        minOrderAmount: 0, maxDiscountAmount: 5000,
        isUsed: false,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      final discount = coupon.calculateDiscount(100000); // 20% = 20,000 → 상한 5,000
      expect(discount, 5000.0);
      print('  ✅ 상한선 쿠폰: 20% × ${fmtAmt(100000)} = ${fmtAmt(20000)} → 상한 적용 → ${fmtAmt(discount)}');
    });

    test('쿠폰 typeLabel', () {
      expect(makeCoupon(type: CouponType.percent, value: 10).typeLabel, '10% 할인');
      expect(makeCoupon(type: CouponType.fixed, value: 3000).typeLabel, '3000원 할인');
      print('  ✅ typeLabel: "10% 할인" / "3000원 할인"');
    });

    test('중복 사용은 모든 쿠폰이 허용된 경우에만 가능하다', () {
      final stackableA = makeCoupon(id: 'stack-a', isStackable: true);
      final stackableB = makeCoupon(id: 'stack-b', isStackable: true);
      final singleUse = makeCoupon(id: 'single-use');

      expect(CouponModel.canStack([stackableA]), isTrue);
      expect(CouponModel.canStack([stackableA, stackableB]), isTrue);
      expect(CouponModel.canStack([stackableA, singleUse]), isFalse);
      expect(CouponModel.canStack([singleUse]), isTrue);
    });

    test('중복 허용 쿠폰은 남은 금액에 순차 적용한다', () {
      final percent = makeCoupon(
        id: 'stack-percent',
        value: 10,
        isStackable: true,
      );
      final fixed = makeCoupon(
        id: 'stack-fixed',
        type: CouponType.fixed,
        value: 3000,
        isStackable: true,
      );
      var remaining = 100000.0;
      var totalDiscount = 0.0;
      for (final coupon in [percent, fixed]) {
        final discount = coupon.calculateDiscount(remaining);
        totalDiscount += discount;
        remaining -= discount;
      }
      expect(totalDiscount, 13000);
      expect(remaining, 87000);
    });
  });

  // ────────────────────────────────────────────
  group('📍 배송지 관리', () {
    test('배송지 생성 및 기본 필드', () {
      final addr = makeAddress();
      expect(addr.recipient, '최혜원');
      expect(addr.isDefault, isTrue);
      expect(addr.address1, isNotEmpty);
      print('  ✅ 배송지: [${addr.label}] ${addr.recipient} / ${addr.phone} / ${addr.address1} ${addr.address2}');
    });

    test('배송지 다수 등록 및 기본 선택', () {
      final addresses = [
        makeAddress(id: 'addr_001', label: '집', recipient: '최혜원', isDefault: true),
        makeAddress(id: 'addr_002', label: '회사', recipient: '최혜원', address1: '서울시 강남구 테헤란로 123', isDefault: false),
        makeAddress(id: 'addr_003', label: '부모님댁', recipient: '최혜원 모', address1: '전남 순천시 조례동 456', isDefault: false),
      ];
      final def = addresses.firstWhere((a) => a.isDefault);
      expect(def.id, 'addr_001');
      expect(addresses.length, 3);
      print('  ✅ 배송지 ${addresses.length}개 등록:');
      for (final a in addresses) {
        print('     ${a.isDefault ? "★" : "○"} [${a.label}] ${a.recipient} — ${a.address1}');
      }
    });

    test('배송지 JSON 직렬화/역직렬화', () {
      final addr = makeAddress();
      final json = addr.toJson();
      final restored = AddressModel.fromJson(json);
      expect(restored.id, addr.id);
      expect(restored.recipient, addr.recipient);
      expect(restored.isDefault, addr.isDefault);
      print('  ✅ JSON 복원: [${restored.label}] ${restored.recipient} / ${restored.address1}');
    });
  });

  // ────────────────────────────────────────────
  group('📋 주문 목록 & 통계', () {
    test('상태별 주문 집계', () {
      final orders = [
        makePersonalOrder(status: OrderStatus.pending),
        makePersonalOrder(status: OrderStatus.pending),
        makePersonalOrder(status: OrderStatus.confirmed),
        makePersonalOrder(status: OrderStatus.processing),
        makePersonalOrder(status: OrderStatus.shipped),
        makePersonalOrder(status: OrderStatus.delivered),
        makePersonalOrder(status: OrderStatus.cancelled),
        makeGroupOrder(status: OrderStatus.pending),
      ];
      final counts = <OrderStatus, int>{};
      for (final o in orders) counts[o.status] = (counts[o.status] ?? 0) + 1;
      expect(counts[OrderStatus.pending], 3);
      expect(counts[OrderStatus.delivered], 1);
      expect(counts[OrderStatus.cancelled], 1);
      print('  ✅ 상태 집계:');
      for (final e in counts.entries) print('     ${e.key.label}: ${e.value}건');
    });

    test('진행중 주문 필터 (결제완료+배송준비+배송중)', () {
      final orders = [
        makePersonalOrder(status: OrderStatus.pending),
        makePersonalOrder(status: OrderStatus.confirmed),
        makePersonalOrder(status: OrderStatus.processing),
        makePersonalOrder(status: OrderStatus.shipped),
        makePersonalOrder(status: OrderStatus.delivered),
        makePersonalOrder(status: OrderStatus.cancelled),
      ];
      final inProgress = orders.where((o) =>
          o.status == OrderStatus.confirmed ||
          o.status == OrderStatus.processing ||
          o.status == OrderStatus.shipped).toList();
      expect(inProgress.length, 3);
      print('  ✅ 진행중: ${inProgress.length}건 (${inProgress.map((o) => o.status.label).join(', ')})');
    });

    test('특정 사용자 주문 필터링', () {
      const mine = 'user_001';
      const other = 'user_999';
      final orders = [
        makePersonalOrder(userId: mine),
        makePersonalOrder(userId: mine),
        makePersonalOrder(userId: other),
        makeGroupOrder(userId: mine),
        makeGroupOrder(userId: other),
      ];
      final myOrders = orders.where((o) => o.userId == mine).toList();
      expect(myOrders.length, 3);
      print('  ✅ 전체 ${orders.length}건 중 내 주문: ${myOrders.length}건');
    });

    test('최근 3개월 필터', () {
      final now = DateTime.now();
      final orders = [
        makePersonalOrder(createdAt: now.subtract(const Duration(days: 10))),
        makePersonalOrder(createdAt: now.subtract(const Duration(days: 60))),
        makePersonalOrder(createdAt: now.subtract(const Duration(days: 100))),
        makePersonalOrder(createdAt: now.subtract(const Duration(days: 120))),
      ];
      final cutoff = now.subtract(const Duration(days: 90));
      final recent = orders.where((o) => o.createdAt.isAfter(cutoff)).toList();
      expect(recent.length, 2);
      print('  ✅ 최근 3개월: ${orders.length}건 중 ${recent.length}건');
    });

    test('총 주문 금액 합산', () {
      final orders = [
        makePersonalOrder(totalAmount: 35000),
        makePersonalOrder(totalAmount: 70000),
        makeGroupOrder(totalAmount: 770000),
      ];
      final total = orders.fold(0.0, (s, o) => s + o.totalAmount);
      expect(total, 875000);
      print('  ✅ 3건 총합: ${fmtAmt(total)}');
    });

    test('최신순 정렬', () {
      final now = DateTime.now();
      final orders = [
        makePersonalOrder(id: 'old', createdAt: now.subtract(const Duration(days: 30))),
        makePersonalOrder(id: 'mid', createdAt: now.subtract(const Duration(days: 10))),
        makePersonalOrder(id: 'new', createdAt: now.subtract(const Duration(days: 1))),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(orders.first.id, 'new');
      expect(orders.last.id, 'old');
      print('  ✅ 최신순: ${orders.map((o) => o.id).join(' → ')}');
    });
  });

  // ────────────────────────────────────────────
  group('💰 금액 포맷', () {
    test('다양한 금액 포맷', () {
      final cases = {
        0.0: '0원',
        1000.0: '1,000원',
        35000.0: '35,000원',
        770000.0: '770,000원',
        1200000.0: '1,200,000원',
      };
      for (final e in cases.entries) {
        expect(fmtAmt(e.key), e.value);
        print('  ✅ ${e.key.toInt()} → ${e.value}');
      }
    });
  });

  // ────────────────────────────────────────────
  group('🧑‍💻 실제 사용자 시나리오', () {
    test('[시나리오 1] 개인 회원 → 상품 찜 → 주문 → 배송완료', () {
      print('\n  📋 시나리오 1: 개인 주문 전체 흐름');

      // 회원 생성
      final user = makeUser();
      print('  ① 사용자: ${user.name} (${user.email})');

      // 상품 찜
      final p = makeProduct(name: '2FIT 라운드넥 티셔츠', price: 35000);
      user.wishlist.add(p.id);
      expect(user.wishlist, contains(p.id));
      print('  ② 찜: ${p.name} (찜 ${user.wishlist.length}개)');

      // 장바구니 → 주문
      final cartItem = makeCartItem(product: p, size: 'M', color: 'Black', quantity: 2);
      expect(cartItem.totalPrice, 70000);
      print('  ③ 장바구니: ${cartItem.product.name} ×${cartItem.quantity} = ${fmtAmt(cartItem.totalPrice)}');

      final item = makeOrderItem(productId: p.id, productName: p.name, quantity: 2, price: p.price);
      var order = makePersonalOrder(userId: user.id, items: [item]);
      expect(order.totalAmount, 70000);
      expect(order.status, OrderStatus.pending);
      print('  ④ 주문: ${order.id} [${order.status.label}] ${fmtAmt(order.totalAmount)}');

      // 배송 흐름
      for (final s in [OrderStatus.confirmed, OrderStatus.processing, OrderStatus.shipped, OrderStatus.delivered]) {
        order = order.copyWith(status: s);
        print('  → ${order.status.label}');
      }
      expect(order.status, OrderStatus.delivered);
      print('  ✅ 시나리오 1 완료\n');
    });

    test('[시나리오 2] 단체주문 → 컬러수정 → 디자인수정 → 추가제작 → 완료', () {
      print('\n  📋 시나리오 2: 단체주문 전체 흐름');

      var order = makeGroupOrder(groupName: '남원FC', groupCount: 22, totalAmount: 770000);
      print('  ① 단체주문: ${order.groupName} ${order.groupCount}벌 ${fmtAmt(order.totalAmount)}');

      // 컬러 수정 1회
      order = order.copyWith(colorEditCount: 1);
      expect(order.canEditColor, isTrue);
      print('  ② 컬러수정 1회 (남은 ${order.remainingColorEdits}회)');

      // 디자인 수정 1회
      order = order.copyWith(designRevisionCount: 1);
      expect(order.canDesignRevision, isTrue);
      print('  ③ 디자인수정 1회 (남은 ${order.remainingDesignRevisions}회)');

      // 추가제작 가능 여부
      expect(order.canOrderAdditionalFree, isTrue);
      print('  ④ 추가제작 가능: ${order.canOrderAdditionalFree}');

      // 상태 흐름
      for (final s in [OrderStatus.confirmed, OrderStatus.processing, OrderStatus.shipped, OrderStatus.delivered]) {
        order = order.copyWith(status: s);
        print('  → ${order.status.label}');
      }
      expect(order.status, OrderStatus.delivered);
      print('  ✅ 시나리오 2 완료\n');
    });

    test('[시나리오 3] 쿠폰 적용 주문 금액 검증', () {
      print('\n  📋 시나리오 3: 쿠폰 적용');

      final item = makeOrderItem(quantity: 2, price: 35000);
      final orderAmount = item.price * item.quantity; // 70,000
      print('  ① 상품 금액: ${fmtAmt(orderAmount)}');

      // 10% 쿠폰
      final coupon = makeCoupon(type: CouponType.percent, value: 10);
      expect(coupon.isValid, isTrue);
      final discount = coupon.calculateDiscount(orderAmount);
      final finalAmt = orderAmount - discount;
      expect(finalAmt, 63000);
      print('  ② 쿠폰: ${coupon.name} (${coupon.value.toInt()}%)');
      print('  ③ 할인: ${fmtAmt(discount)}');
      print('  ④ 최종 결제: ${fmtAmt(finalAmt)}');
      print('  ✅ 시나리오 3 완료\n');
    });

    test('[시나리오 4] 마이페이지 — 복수 주문 관리', () {
      print('\n  📋 시나리오 4: 마이페이지 주문 목록');
      const uid = 'user_001';
      final now = DateTime.now();

      final orders = [
        makePersonalOrder(id: 'ORD-001', userId: uid, status: OrderStatus.pending, createdAt: now),
        makeGroupOrder(id: 'GRP_001', userId: uid, groupName: '남원FC', status: OrderStatus.processing, createdAt: now.subtract(const Duration(days: 5))),
        makePersonalOrder(id: 'ORD-002', userId: uid, status: OrderStatus.delivered, createdAt: now.subtract(const Duration(days: 30))),
        makePersonalOrder(id: 'ORD-003', userId: uid, status: OrderStatus.cancelled, createdAt: now.subtract(const Duration(days: 60))),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(orders.first.id, 'ORD-001');
      final active = orders.where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.refunded).length;
      expect(active, 3);

      print('  전체 ${orders.length}건 (활성 $active건):');
      for (final o in orders) {
        final type = o.orderType == 'group' ? '[단체]' : '[개인]';
        print('  $type ${o.id} — ${o.status.label} — ${fmtAmt(o.totalAmount)}');
      }
      print('  ✅ 시나리오 4 완료\n');
    });

    test('[시나리오 5] 주문 취소 처리', () {
      print('\n  📋 시나리오 5: 주문 취소');

      var order = makePersonalOrder(status: OrderStatus.pending);
      print('  ① 주문 생성: ${order.id} [${order.status.label}]');

      // 취소 가능 여부 확인
      final canCancel = order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
      expect(canCancel, isTrue);
      print('  ② 취소 가능 여부: $canCancel');

      // 취소 처리
      order = order.copyWith(status: OrderStatus.cancelled);
      expect(order.status, OrderStatus.cancelled);
      print('  ③ 취소 완료: ${order.status.label}');
      print('  ✅ 시나리오 5 완료\n');
    });

    test('[시나리오 6] 포인트 적립 & 사용', () {
      print('\n  📋 시나리오 6: 포인트');

      final user = makeUser(points: 0);
      print('  ① 초기 포인트: ${user.points}P');

      // 주문 후 포인트 적립 (주문금액의 1%)
      final orderAmt = 70000;
      final earnedPoints = (orderAmt * 0.01).round();
      user.points += earnedPoints;
      expect(user.points, 700);
      print('  ② 주문 ${fmtAmt(orderAmt.toDouble())} → 적립 ${earnedPoints}P (보유: ${user.points}P)');

      // 다음 주문에 포인트 사용
      final usePoints = 500;
      user.points -= usePoints;
      expect(user.points, 200);
      print('  ③ ${usePoints}P 사용 → 잔여: ${user.points}P');
      print('  ✅ 시나리오 6 완료\n');
    });
  });
}
