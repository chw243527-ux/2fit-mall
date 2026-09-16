import 'models.dart';

/// 단체주문 PDF와 관리자 화면이 공유하는 정규화된 주문 문서 모델입니다.
/// 기존 주문의 문자열·배열·Map·null 혼합 데이터를 읽기 전 안전한 형태로 변환합니다.
class GroupOrderDocument {
  final OrderModel order;
  final Map<String, dynamic> options;
  final List<Map<String, dynamic>> persons;
  final List<String> referenceImageUrls;
  final List<String> waistbandReferenceImageUrls;
  final List<String> attachmentUrls;

  const GroupOrderDocument({
    required this.order,
    required this.options,
    required this.persons,
    required this.referenceImageUrls,
    required this.waistbandReferenceImageUrls,
    required this.attachmentUrls,
  });

  factory GroupOrderDocument.fromOrder(OrderModel order) {
    final source = _map(order.customOptions);
    final normalized = <String, dynamic>{...source};

    String text(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = source[key];
        if (value == null) continue;
        final result = value is String ? value.trim() : value.toString().trim();
        if (result.isNotEmpty) return result;
      }
      return fallback;
    }

    bool boolean(List<String> keys, [bool fallback = false]) {
      for (final key in keys) {
        final value = source[key];
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final lower = value.trim().toLowerCase();
          if (['true', '1', 'yes', 'y', '선택함', '신청함'].contains(lower)) return true;
          if (['false', '0', 'no', 'n', '선택 안 함', '신청하지 않음'].contains(lower)) return false;
        }
      }
      return fallback;
    }

    final rawPersons = _list(source['persons']);
    final persons = rawPersons.map(_map).where((item) => item.isNotEmpty).toList();
    final refUrls = _strings([
      source['refImageUrl'],
      source['maleRefImageUrl'],
      source['femaleRefImageUrl'],
      ..._list(source['refImageUrls']),
      ..._list(source['referenceImageUrls']),
    ]);
    final waistbandUrls = _strings([
      ..._list(source['waistbandRefImageUrls']),
      ..._list(source['waistbandReferenceImageUrls']),
    ]);
    final attachments = _strings([
      ..._list(source['attachmentUrls']),
      ..._list(source['uploadedFileUrls']),
      ..._list(source['designAttachmentUrls']),
      ..._list(source['logoAttachmentUrls']),
      ..._list(source['waistbandDesignAttachmentUrls']),
      ..._list(source['waistbandLogoAttachmentUrls']),
    ]);

    normalized['persons'] = persons;
    normalized['refImageUrls'] = refUrls;
    normalized['waistbandRefImageUrls'] = waistbandUrls;
    normalized['attachmentUrls'] = attachments;
    normalized['hasBottom'] = boolean(['hasBottom'], text(['bottomProduct', 'bottomName']).isNotEmpty);
    normalized['pocket'] = boolean(['pocket', 'pocketSelected']);
    normalized['isExclusive'] = boolean(['isExclusive', 'exclusive', 'designExclusive']);
    normalized['printType'] = text(['printType', 'printTypeLabel'], '-');
    normalized['mainColor'] = text(['mainColor', 'color', 'colorName'], '-');
    normalized['mainColorCode'] = text(['mainColorCode', 'colorCode'], '-');
    normalized['mainColorHex'] = text(['mainColorHex', 'adjustedColorHex', 'colorHex']);
    normalized['waistbandColorName'] = text(['waistbandColorName'], '기본 허리밴드 색상');
    normalized['waistbandColorHex'] = text(['waistbandColorHex', 'waistbandHex']);

    return GroupOrderDocument(
      order: order,
      options: normalized,
      persons: persons,
      referenceImageUrls: refUrls,
      waistbandReferenceImageUrls: waistbandUrls,
      attachmentUrls: attachments,
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
    return <String, dynamic>{};
  }

  static List<dynamic> _list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) return [value.trim()];
    return const <dynamic>[];
  }

  static List<String> _strings(Iterable<dynamic> values) => values
      .where((value) => value != null)
      .map((value) => value is String ? value.trim() : value.toString().trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
}
