// web_utils_html.dart - 웹 플랫폼용 다운로드 유틸 (dart:html 사용)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

/// iOS / iPad Safari 여부 감지
bool _isIOSSafari() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
}

/// 웹에서 파일 다운로드 트리거
/// - iOS Safari  : Base64 Data URL + window.open (다운로드 속성 미지원)
/// - 기타 브라우저: Blob + AnchorElement click (표준)
void downloadFileWeb(Uint8List bytes, String fileName, String mimeType) {
  if (_isIOSSafari()) {
    // ── iOS / iPad Safari 전용 ────────────────────────────────────
    // iOS Safari는 <a download> 속성을 무시하므로 Base64 Data URL로 열기
    try {
      final base64Data = base64Encode(bytes);
      // octet-stream으로 강제해야 iOS에서 파일 저장 옵션이 나타남
      final openUrl = 'data:application/octet-stream;base64,$base64Data';
      html.window.open(openUrl, '_blank');
    } catch (_) {
      // 팝업 차단 등 fallback: Blob URL 방식
      final blob = html.Blob([bytes], 'application/octet-stream');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      Future.delayed(const Duration(seconds: 2), () {
        html.Url.revokeObjectUrl(url);
      });
    }
  } else {
    // ── 표준 브라우저 (Chrome / Firefox / Edge / Android) ─────────
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    // 즉시 해제 시 일부 브라우저에서 실패 → 1초 지연 후 해제
    Future.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  }
}
