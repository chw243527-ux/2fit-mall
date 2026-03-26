// address_search_web_stub.dart - 모바일/비웹 플랫폼용 스텁
import 'package:flutter/widgets.dart';

void registerIframeView(String viewType) {}
void listenForAddress(void Function(Map<String, dynamic>) onResult) {}
void cancelAddressListener() {}
void reloadIframe() {}

class KakaoIframeWidget extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onResult;
  const KakaoIframeWidget({super.key, required this.onResult});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
