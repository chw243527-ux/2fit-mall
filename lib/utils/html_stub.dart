// html_stub.dart - Android/Non-web 플랫폼용 dart:html 스텁
// 웹이 아닌 플랫폼에서 dart:html 참조 시 빈 구현체 제공

class Blob {
  Blob(List<dynamic> parts, [String? type]);
}

class AnchorElement {
  AnchorElement({String? href});
  String? download;
  String? href;
  void click() {}
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}
