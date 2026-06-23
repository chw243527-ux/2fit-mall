import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// 재고 관리 서비스
///
/// ★ Firestore Rules 배포 없이 동작 ★
/// inventory / inventory_logs 컬렉션을 사용하지 않고,
/// products/{id}.stockData  필드에 사이즈×색상 재고를 직접 저장.
/// products 컬렉션은 이미 isAdmin() write가 허용되어 있으므로
/// 별도 Rules 배포 없이 관리자 쓰기가 가능.
///
/// 이력(logs)은 inventory_logs 대신 products/{id}.stockLogs 서브컬렉션에 저장.
/// (서브컬렉션은 부모 문서 권한을 상속 → 별도 Rules 불필요)
class InventoryService {
  static final _db = FirebaseFirestore.instance;
  static final _products = _db.collection('products');

  // ─────────────────────────────────────────────
  //  products → InventoryModel 변환 헬퍼
  // ─────────────────────────────────────────────
  static InventoryModel _toInventory(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    final code = data['productCode'] as String? ?? _generateCode(docId);
    final rawSizes  = data['sizes']  as List<dynamic>? ?? [];
    final rawColors = data['colors'] as List<dynamic>? ?? [];
    final sizes  = rawSizes.isNotEmpty  ? rawSizes.map((e) => e.toString()).toList()  : ['FREE'];
    final colors = rawColors.isNotEmpty ? rawColors.map((e) => e.toString()).toList() : ['기본'];

    // stockData 읽기 (없으면 0으로 초기화)
    final rawStock = data['stockData'] as Map<String, dynamic>? ?? {};
    final Map<String, Map<String, int>> stock = {};
    for (final size in sizes) {
      stock[size] = {};
      for (final color in colors) {
        final colorMap = rawStock[size] as Map<String, dynamic>? ?? {};
        stock[size]![color] = (colorMap[color] as num?)?.toInt() ?? 0;
      }
    }

    // reorderPoint: products 문서에 저장된 값 or 기본값 5
    final reorderPoint = (data['reorderPoint'] as num?)?.toInt() ?? 5;

    return InventoryModel(
      productId:    docId,
      productName:  name,
      productCode:  code,
      stock:        stock,
      reorderPoint: reorderPoint,
      updatedAt:    DateTime.now(),
    );
  }

  static String _generateCode(String productId) {
    final hash = productId.hashCode.abs() % 100000000;
    return hash.toString().padLeft(8, '0');
  }

  // ─────────────────────────────────────────────
  //  재고 현황 읽기
  // ─────────────────────────────────────────────

  /// 전체 상품 재고 목록 (products 컬렉션 직접 읽기)
  /// orderBy 없이 where만 사용 → 복합 인덱스 불필요, 정렬은 클라이언트에서 처리
  static Future<List<InventoryModel>> fetchAll() async {
    final snap = await _products
        .where('isActive', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => _toInventory(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.productName.compareTo(b.productName));
    return list;
  }

  /// fetchAll() 이미 products 기반이므로 동일
  static Future<List<InventoryModel>> fetchAllFromProducts() => fetchAll();

  /// 특정 상품 재고
  static Future<InventoryModel?> fetchOne(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return _toInventory(doc.id, doc.data()!);
  }

  /// 바코드(productCode)로 재고 조회
  static Future<InventoryModel?> fetchByBarcode(String barcode) async {
    final snap = await _products
        .where('productCode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _toInventory(snap.docs.first.id, snap.docs.first.data());
  }

  // ─────────────────────────────────────────────
  //  재고 초기화 (상품 등록 시 자동 호출)
  // ─────────────────────────────────────────────

  /// 상품 등록/수정 시 stockData 초기화 (없을 때만)
  static Future<void> initProduct(ProductModel product) async {
    final doc  = _products.doc(product.id);
    final snap = await doc.get();
    if (!snap.exists) return;
    final data = snap.data()!;

    // 이미 stockData가 있으면 건드리지 않음
    if ((data['stockData'] as Map?)?.isNotEmpty == true) return;

    final sizes  = product.sizes.isNotEmpty  ? product.sizes  : ['FREE'];
    final colors = product.colors.isNotEmpty ? product.colors : ['기본'];
    final Map<String, Map<String, int>> stockData = {
      for (final s in sizes) s: {for (final c in colors) c: 0},
    };

    // productCode 없으면 자동 생성
    final code = product.productCode.isNotEmpty
        ? product.productCode
        : _generateCode(product.id);

    await doc.update({
      'stockData':   stockData,
      'productCode': code,
    });
  }

  /// 전체 상품 일괄 동기화
  /// - stockData 없으면 생성 (사이즈×색상 = 0)
  /// - productCode 없으면 자동 생성
  /// - 반환값: 신규 생성된 상품 수
  static Future<int> syncAllProducts(List<ProductModel> products) async {
    int created = 0;
    for (final p in products) {
      final code = p.productCode.isNotEmpty
          ? p.productCode
          : _generateCode(p.id);

      final doc  = _products.doc(p.id);
      final snap = await doc.get();
      if (!snap.exists) continue;

      final data = snap.data()!;
      final existing = data['stockData'] as Map?;
      final Map<String, dynamic> updates = {};

      // productCode 없으면 저장
      if ((data['productCode'] as String?)?.isEmpty ?? true) {
        updates['productCode'] = code;
      }

      // stockData 없으면 0으로 초기화
      if (existing == null || existing.isEmpty) {
        final sizes  = p.sizes.isNotEmpty  ? p.sizes  : ['FREE'];
        final colors = p.colors.isNotEmpty ? p.colors : ['기본'];
        updates['stockData'] = {
          for (final s in sizes) s: {for (final c in colors) c: 0},
        };
        created++;
      }

      if (updates.isNotEmpty) {
        await doc.update(updates);
      }
    }
    return created;
  }

  // ─────────────────────────────────────────────
  //  입고
  // ─────────────────────────────────────────────
  static Future<void> incoming({
    required String productId,
    required String size,
    required String color,
    required int quantity,
    String memo = '',
    required String adminId,
  }) => _changeStock(
    productId: productId,
    size: size,
    color: color,
    delta: quantity,
    type: InventoryLogType.incoming,
    memo: memo,
    adminId: adminId,
  );

  // ─────────────────────────────────────────────
  //  출고
  // ─────────────────────────────────────────────
  static Future<void> outgoing({
    required String productId,
    required String size,
    required String color,
    required int quantity,
    String memo = '',
    required String adminId,
  }) => _changeStock(
    productId: productId,
    size: size,
    color: color,
    delta: -quantity,
    type: InventoryLogType.outgoing,
    memo: memo,
    adminId: adminId,
  );

  // ─────────────────────────────────────────────
  //  재고조정 (절대값 설정)
  // ─────────────────────────────────────────────
  static Future<void> adjust({
    required String productId,
    required String size,
    required String color,
    required int newQty,
    String memo = '',
    required String adminId,
  }) async {
    final inv = await fetchOne(productId);
    if (inv == null) return;
    final before = inv.stockForSizeColor(size, color);
    final delta  = newQty - before;
    await _changeStock(
      productId: productId,
      size: size,
      color: color,
      delta: delta,
      type: InventoryLogType.adjustment,
      memo: memo,
      adminId: adminId,
    );
  }

  // ─────────────────────────────────────────────
  //  공통 재고 변경 (products 문서 트랜잭션)
  // ─────────────────────────────────────────────
  static Future<void> _changeStock({
    required String productId,
    required String size,
    required String color,
    required int delta,           // 양수=증가, 음수=감소
    required InventoryLogType type,
    required String memo,
    required String adminId,
  }) async {
    final prodDoc = _products.doc(productId);
    final logRef  = prodDoc.collection('stockLogs').doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(prodDoc);
      if (!snap.exists) throw Exception('상품 문서 없음: $productId');

      final data = snap.data()!;
      final inv  = _toInventory(snap.id, data);
      final before = inv.stockForSizeColor(size, color);
      final after  = (before + delta).clamp(0, 999999);

      // stockData 업데이트 (dot-notation으로 해당 셀만 수정)
      tx.update(prodDoc, {
        'stockData.$size.$color': after,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 이력 기록 (서브컬렉션 stockLogs)
      tx.set(logRef, InventoryLog(
        id:          logRef.id,
        productId:   productId,
        productName: inv.productName,
        productCode: inv.productCode,
        size:        size,
        color:       color,
        type:        type,
        quantity:    delta.abs(),
        beforeQty:   before,
        afterQty:    after,
        memo:        memo,
        adminId:     adminId,
        createdAt:   DateTime.now(),
      ).toJson());
    });
  }

  // ─────────────────────────────────────────────
  //  이력 조회 (stockLogs 서브컬렉션)
  // ─────────────────────────────────────────────

  /// 최근 이력 N건 (전체 상품 — collectionGroup 쿼리)
  static Future<List<InventoryLog>> fetchLogs({int limit = 100}) async {
    try {
      final snap = await _db
          .collectionGroup('stockLogs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => InventoryLog.fromJson(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 특정 상품 이력
  static Future<List<InventoryLog>> fetchLogsByProduct(
      String productId, {int limit = 50}) async {
    final snap = await _products
        .doc(productId)
        .collection('stockLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => InventoryLog.fromJson(d.id, d.data()))
        .toList();
  }

  /// 날짜 범위 이력 (특정 상품 기준)
  static Future<List<InventoryLog>> fetchLogsByDate({
    required DateTime from,
    required DateTime to,
    int limit = 200,
  }) async {
    try {
      final snap = await _db
          .collectionGroup('stockLogs')
          .where('createdAt', isGreaterThanOrEqualTo: from.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: to.toIso8601String())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => InventoryLog.fromJson(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  //  발주 기준 수량 업데이트
  // ─────────────────────────────────────────────
  static Future<void> updateReorderPoint(
      String productId, int reorderPoint) async {
    await _products.doc(productId).update({'reorderPoint': reorderPoint});
  }

  // ─────────────────────────────────────────────
  //  부족 재고 목록
  // ─────────────────────────────────────────────
  static Future<List<InventoryModel>> fetchLowStock() async {
    final all = await fetchAll();
    return all.where((inv) => inv.needsReorder).toList();
  }
}
