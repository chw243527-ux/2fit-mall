import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// 재고 관리 서비스
/// Firestore 컬렉션:
///   inventory/{productId}          — 사이즈별 재고 현황
///   inventory_logs/{autoId}        — 입출고 이력
class InventoryService {
  static final _db   = FirebaseFirestore.instance;
  static final _inv  = _db.collection('inventory');
  static final _logs = _db.collection('inventory_logs');

  // ─────────────────────────────────────────────
  //  재고 현황 읽기
  // ─────────────────────────────────────────────

  /// 모든 상품 재고 현황
  static Future<List<InventoryModel>> fetchAll() async {
    final snap = await _inv.orderBy('productName').get();
    return snap.docs
        .map((d) => InventoryModel.fromJson(d.id, d.data()))
        .toList();
  }

  /// 특정 상품 재고
  static Future<InventoryModel?> fetchOne(String productId) async {
    final doc = await _inv.doc(productId).get();
    if (!doc.exists) return null;
    return InventoryModel.fromJson(doc.id, doc.data()!);
  }

  /// 바코드(productCode)로 재고 조회
  static Future<InventoryModel?> fetchByBarcode(String barcode) async {
    final snap = await _inv
        .where('productCode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InventoryModel.fromJson(snap.docs.first.id, snap.docs.first.data());
  }

  // ─────────────────────────────────────────────
  //  재고 초기화 (상품 등록 시 자동 호출)
  // ─────────────────────────────────────────────

  /// 상품 등록/수정 시 재고 문서 생성 (없을 때만)
  static Future<void> initProduct(ProductModel product) async {
    final doc = _inv.doc(product.id);
    final snap = await doc.get();
    if (snap.exists) return; // 이미 있으면 건드리지 않음

    // 사이즈×색상 모두 0으로 초기화
    final Map<String, Map<String, int>> stock = {};
    for (final size in product.sizes) {
      stock[size] = {};
      for (final color in product.colors) {
        stock[size]![color] = 0;
      }
    }

    await doc.set(InventoryModel(
      productId:   product.id,
      productName: product.name,
      productCode: product.productCode.isNotEmpty
          ? product.productCode
          : _generateCode(product.id),
      stock:       stock,
      reorderPoint: 5,
      updatedAt:   DateTime.now(),
    ).toJson());
  }

  /// productCode 자동 생성 (8자리 숫자)
  static String _generateCode(String productId) {
    final hash = productId.hashCode.abs() % 100000000;
    return hash.toString().padLeft(8, '0');
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
  //  공통 재고 변경 (Firestore 트랜잭션)
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
    final invDoc  = _inv.doc(productId);
    final logRef  = _logs.doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(invDoc);
      if (!snap.exists) throw Exception('재고 문서 없음: $productId');

      final inv = InventoryModel.fromJson(snap.id, snap.data()!);
      final before = inv.stockForSizeColor(size, color);
      final after  = (before + delta).clamp(0, 999999);

      // stock 업데이트
      final newStock = Map<String, Map<String, int>>.from(
        inv.stock.map((s, cm) => MapEntry(s, Map<String, int>.from(cm))),
      );
      newStock.putIfAbsent(size, () => {})[color] = after;

      tx.update(invDoc, {
        'stock.$size.$color': after,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 이력 기록
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
  //  이력 조회
  // ─────────────────────────────────────────────

  /// 최근 이력 N건 (전체)
  static Future<List<InventoryLog>> fetchLogs({int limit = 100}) async {
    final snap = await _logs
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => InventoryLog.fromJson(d.id, d.data()))
        .toList();
  }

  /// 특정 상품 이력
  static Future<List<InventoryLog>> fetchLogsByProduct(
      String productId, {int limit = 50}) async {
    final snap = await _logs
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => InventoryLog.fromJson(d.id, d.data()))
        .toList();
  }

  /// 날짜 범위 이력
  static Future<List<InventoryLog>> fetchLogsByDate({
    required DateTime from,
    required DateTime to,
    int limit = 200,
  }) async {
    final snap = await _logs
        .where('createdAt', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: to.toIso8601String())
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => InventoryLog.fromJson(d.id, d.data()))
        .toList();
  }

  // ─────────────────────────────────────────────
  //  발주 기준 수량 업데이트
  // ─────────────────────────────────────────────
  static Future<void> updateReorderPoint(
      String productId, int reorderPoint) async {
    await _inv.doc(productId).update({'reorderPoint': reorderPoint});
  }

  // ─────────────────────────────────────────────
  //  부족 재고 목록
  // ─────────────────────────────────────────────
  static Future<List<InventoryModel>> fetchLowStock() async {
    final all = await fetchAll();
    return all.where((inv) => inv.needsReorder).toList();
  }
}
