// address_search_widget.dart
// 주소 검색 위젯
// - 웹: HtmlElementView로 kakao_postcode.html iframe 직접 임베드 → postMessage 수신
// - 모바일: WebView 임베드 방식
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 웹 전용 구현 (조건부 import)
import 'address_search_web_stub.dart'
    if (dart.library.html) 'address_search_web_impl.dart' as addr_web;

// 모바일 전용
import 'package:webview_flutter/webview_flutter.dart';

// ── 결과 모델 ──
class AddressResult {
  final String zonecode;
  final String address;
  final String roadAddress;
  final String jibunAddress;

  const AddressResult({
    required this.zonecode,
    required this.address,
    required this.roadAddress,
    required this.jibunAddress,
  });
}

/// 주소 검색 BottomSheet 표시
Future<AddressResult?> showAddressSearch(BuildContext context) {
  return showModalBottomSheet<AddressResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddressSearchSheet(),
  );
}

// ── BottomSheet 컨테이너 ──
class _AddressSearchSheet extends StatelessWidget {
  const _AddressSearchSheet();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Color(0xFF6A1B9A), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('주소 검색',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // 안내 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF3E5F5),
            child: const Text(
              '도로명·지번·건물명으로 검색 후 선택하면 자동 입력됩니다.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6A1B9A),
                  fontWeight: FontWeight.w500),
            ),
          ),
          // 바디 (웹 or 모바일)
          Expanded(
            child: kIsWeb
                ? _AddressWebBody(
                    onResult: (r) => Navigator.pop(context, r),
                  )
                : _AddressMobileBody(
                    onResult: (r) => Navigator.pop(context, r),
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 웹 전용: HtmlElementView iframe 직접 임베드
// ══════════════════════════════════════════════════════════
class _AddressWebBody extends StatefulWidget {
  final ValueChanged<AddressResult> onResult;
  const _AddressWebBody({required this.onResult});

  @override
  State<_AddressWebBody> createState() => _AddressWebBodyState();
}

class _AddressWebBodyState extends State<_AddressWebBody> {
  @override
  Widget build(BuildContext context) {
    return addr_web.KakaoIframeWidget(
      onResult: (data) {
        final result = AddressResult(
          zonecode: data['zonecode']?.toString() ?? '',
          address: data['address']?.toString() ?? '',
          roadAddress: data['roadAddress']?.toString() ?? '',
          jibunAddress: data['jibunAddress']?.toString() ?? '',
        );
        widget.onResult(result);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// 모바일 전용: WebView 임베드
// ══════════════════════════════════════════════════════════
class _AddressMobileBody extends StatefulWidget {
  final ValueChanged<AddressResult> onResult;
  const _AddressMobileBody({required this.onResult});

  @override
  State<_AddressMobileBody> createState() => _AddressMobileBodyState();
}

class _AddressMobileBodyState extends State<_AddressMobileBody> {
  late final WebViewController _ctrl;
  bool _loading = true;

  static const _html = r'''<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
<style>html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;}#wrap{width:100%;height:100%;}</style>
</head><body>
<div id="wrap"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
new daum.Postcode({
  oncomplete:function(d){
    var addr=d.userSelectedType==='R'?d.roadAddress:d.jibunAddress;
    AddrBridge.postMessage(JSON.stringify({
      zonecode:d.zonecode,address:addr,
      roadAddress:d.roadAddress||'',jibunAddress:d.jibunAddress||''
    }));
  },width:'100%',height:'100%',animation:false
}).embed(document.getElementById('wrap'),{autoClose:false});
</script></body></html>''';

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..addJavaScriptChannel('AddrBridge', onMessageReceived: (msg) {
        try {
          final data = jsonDecode(msg.message) as Map<String, dynamic>;
          final result = AddressResult(
            zonecode: data['zonecode']?.toString() ?? '',
            address: data['address']?.toString() ?? '',
            roadAddress: data['roadAddress']?.toString() ?? '',
            jibunAddress: data['jibunAddress']?.toString() ?? '',
          );
          widget.onResult(result);
        } catch (_) {}
      })
      ..loadHtmlString(_html);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      WebViewWidget(controller: _ctrl),
      if (_loading)
        const Center(
            child: CircularProgressIndicator(color: Color(0xFF6A1B9A))),
    ]);
  }
}
