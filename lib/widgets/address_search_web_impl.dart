// address_search_web_impl.dart
// 웹 전용: HtmlElementView iframe 임베드 + window.onMessage 수신
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

StreamSubscription? _sub;
html.IFrameElement? _iframeEl;
String? _registeredViewType;

/// iframe 뷰 등록 (앱 시작 시 또는 첫 사용 시 1회)
void registerIframeView(String viewType) {
  if (_registeredViewType == viewType) return;
  _registeredViewType = viewType;

  // ignore: avoid_web_libraries_in_flutter
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = '/kakao_postcode.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'same-origin'
      ..setAttribute('sandbox',
          'allow-scripts allow-same-origin allow-forms allow-popups');
    _iframeEl = iframe;
    return iframe;
  });
}

/// postMessage 리스너 등록
void listenForAddress(void Function(Map<String, dynamic>) onResult) {
  _sub?.cancel();
  _sub = null;

  bool called = false;
  _sub = html.window.onMessage.listen((event) {
    if (called) return;
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.isEmpty) return;
      if (!raw.contains('"KAKAO_ADDRESS"')) return;
      if (!raw.contains('"address"')) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);

      final addr = data['address']?.toString() ?? '';
      if (addr.isEmpty) return;

      called = true;
      _sub?.cancel();
      _sub = null;
      onResult(data);
    } catch (_) {}
  });
}

/// 리스너 취소
void cancelAddressListener() {
  _sub?.cancel();
  _sub = null;
}

/// iframe src 리로드 (재검색 시)
void reloadIframe() {
  try {
    _iframeEl?.src = '/kakao_postcode.html?t=${DateTime.now().millisecondsSinceEpoch}';
  } catch (_) {}
}

// ── Flutter Widget: iframe 래퍼 ──
class KakaoIframeWidget extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onResult;
  const KakaoIframeWidget({super.key, required this.onResult});

  @override
  State<KakaoIframeWidget> createState() => _KakaoIframeWidgetState();
}

class _KakaoIframeWidgetState extends State<KakaoIframeWidget> {
  static const _viewType = 'kakao-address-iframe';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    registerIframeView(_viewType);
    listenForAddress((data) {
      if (mounted) widget.onResult(data);
    });
    // iframe 로드 후 약간의 지연
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    cancelAddressListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HtmlElementView(viewType: _viewType),
        if (!_ready)
          Container(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF6A1B9A))),
            ),
          ),
      ],
    );
  }
}
