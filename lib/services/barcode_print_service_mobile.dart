import '../models/models.dart';

class BarcodePrintService {
  static void printLabels({required InventoryModel inventory, required List<String> sizes, required List<String> colors, int copies = 1}) {}

  static String _buildBarcode(String productCode, String size, String color) {
    final pc = productCode.replaceAll(RegExp(r'\D'), '').padLeft(8, '0').substring(0, 8);
    final sizeIdx = (size.hashCode.abs() % 100).toString().padLeft(2, '0');
    final colorIdx = (color.hashCode.abs() % 100).toString().padLeft(2, '0');
    final body = pc + sizeIdx + colorIdx;
    var odd = 0, even = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.tryParse(body[i]) ?? 0;
      if (i.isEven) odd += digit; else even += digit;
    }
    return body + ((10 - ((odd + even * 3) % 10)) % 10).toString();
  }

  static List<BarcodeItem> generateBarcodes(InventoryModel inventory) {
    final result = <BarcodeItem>[];
    for (final size in inventory.stock.keys) {
      for (final color in inventory.stock[size]!.keys) {
        result.add(BarcodeItem(productId: inventory.productId, productName: inventory.productName, size: size, color: color, barcode: _buildBarcode(inventory.productCode, size, color)));
      }
    }
    return result;
  }
}

class BarcodeItem {
  final String productId;
  final String productName;
  final String size;
  final String color;
  final String barcode;
  const BarcodeItem({required this.productId, required this.productName, required this.size, required this.color, required this.barcode});
}
