// web_utils.dart - 비웹 플랫폼용 다운로드 유틸 (스텁)
import 'dart:typed_data';

/// 비웹 플랫폼에서는 파일 다운로드 불가 - 아무것도 하지 않음
void downloadFileWeb(Uint8List bytes, String fileName, String mimeType) {
  // Android/iOS에서는 동작하지 않음 (웹 전용 기능)
}
