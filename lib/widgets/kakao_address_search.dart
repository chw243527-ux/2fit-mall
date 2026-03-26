// kakao_address_search.dart
// 카카오 우편번호 서비스
// - 웹(kIsWeb): JS interop + 팝업 방식
// - 모바일: WebView 방식
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

// 모바일에서만 사용
import 'package:webview_flutter/webview_flutter.dart';

// 웹 전용 구현은 별도 파일로 분리 (조건부 import)
import 'kakao_address_web_stub.dart'
    if (dart.library.html) 'kakao_address_web_impl.dart' as web_impl;

class KakaoAddressResult {
  final String zonecode;
  final String address;
  final String roadAddress;
  final String jibunAddress;
  const KakaoAddressResult({
    required this.zonecode,
    required this.address,
    required this.roadAddress,
    required this.jibunAddress,
  });
}

Future<KakaoAddressResult?> showKakaoAddressSearch(BuildContext context) {
  return showModalBottomSheet<KakaoAddressResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _KakaoAddressSheet(),
  );
}

class _KakaoAddressSheet extends StatelessWidget {
  const _KakaoAddressSheet();
  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF1A1A2E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loc.kakaoAddressSearch,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
          Expanded(
            child: kIsWeb
                ? const _KakaoWebViewWeb()
                : const _KakaoWebView(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 모바일 전용: WebViewController
// ─────────────────────────────────────────────
class _KakaoWebView extends StatefulWidget {
  const _KakaoWebView();
  @override
  State<_KakaoWebView> createState() => _KakaoWebViewState();
}

class _KakaoWebViewState extends State<_KakaoWebView> {
  late final WebViewController _ctrl;
  bool _isLoading = true;
  String? _errMsg;

  static const String _pageHtml = r'''
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
<style>
  html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background:#fff;}
  #layer{width:100%;height:100%;}
</style>
</head>
<body>
<div id="layer"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
function ready(){
  new daum.Postcode({
    width:'100%',
    height:'100%',
    animation:false,
    oncomplete:function(d){
      var addr = d.userSelectedType==='R' ? d.roadAddress : d.jibunAddress;
      var payload = JSON.stringify({
        zonecode: d.zonecode,
        address: addr,
        roadAddress: d.roadAddress,
        jibunAddress: d.jibunAddress
      });
      try{ AddrBridge.postMessage(payload); }catch(e){}
    }
  }).embed(document.getElementById('layer'));
}
if(document.readyState==='loading'){
  document.addEventListener('DOMContentLoaded',ready);
}else{ ready(); }
</script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { _isLoading = true; _errMsg = null; }),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (err) => setState(() {
          _isLoading = false;
          _errMsg = '주소 검색 로딩 실패\n인터넷 연결을 확인해주세요.';
          if (kDebugMode) debugPrint('WebView error: ${err.description}');
        }),
      ))
      ..addJavaScriptChannel('AddrBridge', onMessageReceived: (msg) {
        try {
          final data = jsonDecode(msg.message) as Map<String, dynamic>;
          final result = KakaoAddressResult(
            zonecode:    data['zonecode']     as String? ?? '',
            address:     data['address']      as String? ?? '',
            roadAddress: data['roadAddress']  as String? ?? '',
            jibunAddress:data['jibunAddress'] as String? ?? '',
          );
          if (mounted) Navigator.pop(context, result);
        } catch (e) {
          if (kDebugMode) debugPrint('주소 파싱 오류: $e');
        }
      })
      ..loadHtmlString(_pageHtml);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    if (_errMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 12),
            Text(_errMsg!, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _isLoading = true; _errMsg = null; });
                _ctrl.loadHtmlString(_pageHtml);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(loc.kakaoAddressRetry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E)),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: _ctrl),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                      color: Color(0xFF1A1A2E), strokeWidth: 3),
                  const SizedBox(height: 12),
                  Text(loc.kakaoAddressLoading,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 웹 전용: iframe 방식 카카오 주소 검색
// ─────────────────────────────────────────────
class _KakaoWebViewWeb extends StatefulWidget {
  const _KakaoWebViewWeb();
  @override
  State<_KakaoWebViewWeb> createState() => _KakaoWebViewWebState();
}

class _KakaoWebViewWebState extends State<_KakaoWebViewWeb> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    web_impl.registerKakaoIframeListener((data) {
      if (_done) return;
      _done = true;
      final result = KakaoAddressResult(
        zonecode:     data['zonecode']     as String? ?? '',
        address:      data['address']      as String? ?? '',
        roadAddress:  data['roadAddress']  as String? ?? '',
        jibunAddress: data['jibunAddress'] as String? ?? '',
      );
      // mounted 체크 후 현재 context로 pop (BottomSheet 닫기 + 결과 반환)
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return web_impl.buildKakaoIframeView();
  }
}
