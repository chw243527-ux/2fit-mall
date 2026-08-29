// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import '../models/models.dart';

/// 바코드 라벨 프린트 서비스 (Flutter Web)
/// barcode_widget 패키지로 SVG 렌더링 → window.print() 로 모든 프린터 출력
class BarcodePrintService {
  /// 단일 상품 바코드 라벨 HTML 생성 후 프린트
  static void printLabels({
    required InventoryModel inventory,
    required List<String> sizes,
    required List<String> colors,
    int copies = 1,
  }) {
    final labels = <String>[];
    for (final size in sizes) {
      for (final color in colors) {
        final barcode = _buildBarcode(inventory.productCode, size, color);
        for (var i = 0; i < copies; i++) {
          labels.add(_labelHtml(
            productName: inventory.productName,
            productCode: inventory.productCode,
            size: size,
            color: color,
            barcode: barcode,
          ));
        }
      }
    }
    _openPrintWindow(labels);
  }

  /// productCode + size + color → 13자리 바코드 문자열 생성
  /// 형식: PC(8) + SIZE_IDX(2) + COLOR_IDX(2) + CHECK(1)
  static String _buildBarcode(String productCode, String size, String color) {
    // productCode 숫자 8자리 보정
    final pc = productCode.replaceAll(RegExp(r'\D'), '').padLeft(8, '0').substring(0, 8);
    final sizeIdx  = (size.hashCode.abs()  % 100).toString().padLeft(2, '0');
    final colorIdx = (color.hashCode.abs() % 100).toString().padLeft(2, '0');
    final body     = pc + sizeIdx + colorIdx;
    final check    = _ean13Check(body);
    return body + check.toString();
  }

  /// EAN-13 체크 디짓
  static int _ean13Check(String body12) {
    var odd = 0, even = 0;
    for (var i = 0; i < 12; i++) {
      final d = int.tryParse(body12[i]) ?? 0;
      if (i.isEven) odd  += d;
      else           even += d;
    }
    final total = odd + even * 3;
    return (10 - (total % 10)) % 10;
  }

  /// SVG 바코드 (Code128 스타일 — CSS로 간단 렌더링)
  static String _svgBarcode(String code) {
    // barcode_widget 은 Flutter 위젯이므로 웹 프린트에서는
    // CSS/JS 없이 표현하기 위해 DATA URI 방식 대신
    // JsBarcode CDN을 사용해 <canvas>에 렌더링
    return '<canvas id="bc_$code" style="width:160px;height:60px;"></canvas>'
        '<script>JsBarcode("#bc_$code","$code",{format:"CODE128",'
        'width:2,height:60,displayValue:true,fontSize:11,margin:4});</script>';
  }

  static String _labelHtml({
    required String productName,
    required String productCode,
    required String size,
    required String color,
    required String barcode,
  }) {
    return '''
<div class="label">
  <div class="pname">${_esc(productName)}</div>
  <div class="meta">
    <span class="badge">$size</span>
    <span class="badge">$color</span>
  </div>
  ${_svgBarcode(barcode)}
  <div class="code">$barcode</div>
</div>''';
  }

  static String _esc(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  static void _openPrintWindow(List<String> labels) {
    final body = labels.join('\n');
    final html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>바코드 라벨 출력</title>
<script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: "Malgun Gothic", sans-serif; background: #fff; }
  .grid {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    padding: 10px;
  }
  .label {
    width: 180px;
    border: 1px solid #ccc;
    border-radius: 6px;
    padding: 8px;
    text-align: center;
    page-break-inside: avoid;
  }
  .pname {
    font-size: 10px;
    font-weight: bold;
    margin-bottom: 4px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .meta { margin-bottom: 4px; }
  .badge {
    display: inline-block;
    background: #f0f0f0;
    border: 1px solid #ddd;
    border-radius: 3px;
    font-size: 9px;
    padding: 1px 5px;
    margin: 0 2px;
  }
  .code { font-size: 9px; color: #555; margin-top: 2px; }
  @media print {
    body { margin: 0; }
    .grid { gap: 4px; padding: 4px; }
    .label { border: 1px solid #999; }
  }
</style>
</head>
<body>
<div class="grid">
$body
</div>
<script>
window.onload = function() {
  // JsBarcode 가 모두 렌더링된 후 프린트
  setTimeout(function() { window.print(); }, 600);
};
</script>
</body>
</html>''';

    js.context.callMethod('eval', ['''
(function(){
  var w = window.open('','_blank','width=900,height=700');
  w.document.open();
  w.document.write(${_jsString(html)});
  w.document.close();
})();
''']);
  }

  /// Dart 문자열 → JS 문자열 리터럴 (백틱 템플릿)
  static String _jsString(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll('`',  '\\`')
        .replaceAll('\$',  '\\\$');
    return '`$escaped`';
  }

  // ─────────────────────────────────────────────
  //  바코드 코드 생성 (표시용)
  // ─────────────────────────────────────────────

  /// 상품 전체 바코드 목록 반환 (사이즈×색상)
  static List<BarcodeItem> generateBarcodes(InventoryModel inventory) {
    final result = <BarcodeItem>[];
    for (final size in inventory.stock.keys) {
      for (final color in inventory.stock[size]!.keys) {
        result.add(BarcodeItem(
          productId:   inventory.productId,
          productName: inventory.productName,
          size:        size,
          color:       color,
          barcode:     _buildBarcode(inventory.productCode, size, color),
        ));
      }
    }
    return result;
  }
}

/// 바코드 항목 데이터
class BarcodeItem {
  final String productId;
  final String productName;
  final String size;
  final String color;
  final String barcode;
  const BarcodeItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.barcode,
  });
}
