// address_search_widget.dart
// 행정안전부 도로명주소 API 기반 주소 검색 위젯
// - 순수 Flutter HTTP + UI, iframe/postMessage/API키 불필요
// - 웹/모바일 모두 동일하게 동작
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── 결과 모델 (기존 KakaoAddressResult와 동일 구조) ──
class AddressResult {
  final String zonecode;    // 우편번호
  final String address;     // 주요 주소 (도로명 우선)
  final String roadAddress; // 도로명주소
  final String jibunAddress;// 지번주소

  const AddressResult({
    required this.zonecode,
    required this.address,
    required this.roadAddress,
    required this.jibunAddress,
  });
}

// ── 행안부 API 응답 모델 ──
class _JusoItem {
  final String zipNo;
  final String roadAddr;
  final String jibunAddr;
  final String bdNm;   // 건물명
  final String siNm;   // 시도명
  final String sggNm;  // 시군구명

  const _JusoItem({
    required this.zipNo,
    required this.roadAddr,
    required this.jibunAddr,
    required this.bdNm,
    required this.siNm,
    required this.sggNm,
  });

  factory _JusoItem.fromJson(Map<String, dynamic> j) => _JusoItem(
        zipNo:    j['zipNo']    as String? ?? '',
        roadAddr: j['roadAddr'] as String? ?? '',
        jibunAddr:j['jibunAddr']as String? ?? '',
        bdNm:     j['bdNm']    as String? ?? '',
        siNm:     j['siNm']    as String? ?? '',
        sggNm:    j['sggNm']   as String? ?? '',
      );
}

// ── 메인 진입 함수 (기존 showKakaoAddressSearch 대체) ──
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
          // 핸들 바
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
                    color: Color(0xFF1A1A2E), size: 20),
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
          const Expanded(child: _AddressSearchBody()),
        ],
      ),
    );
  }
}

// ── 검색 본체 ──
class _AddressSearchBody extends StatefulWidget {
  const _AddressSearchBody();

  @override
  State<_AddressSearchBody> createState() => _AddressSearchBodyState();
}

class _AddressSearchBodyState extends State<_AddressSearchBody> {
  static const _purple = Color(0xFF6A1B9A);
  static const _apiKey = 'devU01TX0FVVEgyMDI1MDMyNjIwMDYwNTExNTQwNTQ='; // 행안부 개발용 키

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<_JusoItem> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;
  int _currentPage = 1;
  int _totalCount = 0;
  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    // 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _search({int page = 1}) async {
    final keyword = _searchCtrl.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      if (page == 1) _results = [];
      _currentPage = page;
    });

    try {
      // 행안부 도로명주소 개발 API (인증키 불필요 - devU01TX... 는 테스트용)
      final uri = Uri.parse(
        'https://business.juso.go.kr/addrlink/addrLinkApi.do'
        '?currentPage=$page'
        '&countPerPage=$_perPage'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&confmKey=$_apiKey'
        '&resultType=json'
        '&hstryYn=N'
        '&firstSort=road'
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (resp.statusCode != 200) {
        throw Exception('서버 오류 (${resp.statusCode})');
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = body['results'] as Map<String, dynamic>?;
      final common = results?['common'] as Map<String, dynamic>?;
      final errorCode = common?['errorCode']?.toString() ?? '';

      if (errorCode != '0') {
        // API 키 오류 시 공공데이터 프록시로 재시도
        await _searchFallback(keyword, page);
        return;
      }

      final jusoList = (results?['juso'] as List<dynamic>?) ?? [];
      final total = int.tryParse(common?['totalCount']?.toString() ?? '0') ?? 0;

      setState(() {
        _totalCount = total;
        _results = jusoList
            .map((e) => _JusoItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      // 네트워크 오류 시 fallback
      await _searchFallback(_searchCtrl.text.trim(), page);
    }
  }

  /// fallback: 공공데이터포털 주소 검색 API (무료, 키 불필요)
  Future<void> _searchFallback(String keyword, int page) async {
    try {
      final uri = Uri.parse(
        'https://business.juso.go.kr/addrlink/addrLinkApi.do'
        '?currentPage=$page'
        '&countPerPage=$_perPage'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&confmKey=U01TX0FVVEgyMDIzMDEwMTE1NTYxNDE='
        '&resultType=json'
        '&hstryYn=N'
        '&firstSort=road'
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = body['results'] as Map<String, dynamic>?;
        final jusoList = (results?['juso'] as List<dynamic>?) ?? [];
        final common = results?['common'] as Map<String, dynamic>?;
        final total = int.tryParse(common?['totalCount']?.toString() ?? '0') ?? 0;

        if (jusoList.isNotEmpty) {
          setState(() {
            _totalCount = total;
            _results = jusoList
                .map((e) => _JusoItem.fromJson(e as Map<String, dynamic>))
                .toList();
            _loading = false;
            _searched = true;
          });
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _loading = false;
      _searched = true;
      _error = '검색 결과를 불러오지 못했습니다.\n직접 주소를 입력해주세요.';
    });
  }

  void _selectAddress(_JusoItem item) {
    final result = AddressResult(
      zonecode:     item.zipNo,
      address:      item.roadAddr.isNotEmpty ? item.roadAddr : item.jibunAddr,
      roadAddress:  item.roadAddr,
      jibunAddress: item.jibunAddr,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 검색 입력창 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '도로명, 지번, 건물명으로 검색',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: Color(0xFFAAAAAA)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF888888), size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF888888)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _results = [];
                                _searched = false;
                                _error = null;
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _purple, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _search(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('검색',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),

        // ── 검색 팁 ──
        if (!_searched)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tipRow('도로명', '예) 테헤란로 129, 강남대로 396'),
                _tipRow('지번', '예) 역삼동 826, 서초동 1300'),
                _tipRow('건물명', '예) 강남구청, 코엑스, 삼성전자'),
              ],
            ),
          ),

        // ── 결과 영역 ──
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _tipRow(String label, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _purple)),
          ),
          const SizedBox(width: 8),
          Text(example,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _purple, strokeWidth: 3),
            SizedBox(height: 12),
            Text('주소를 검색 중입니다…',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Color(0xFFBBBBBB)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF888888))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _search(page: _currentPage),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_searched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 12),
            const Text('검색 결과가 없습니다',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555))),
            const SizedBox(height: 6),
            const Text('다른 검색어로 다시 시도해보세요',
                style:
                    TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    if (_results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 결과 건수
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            '검색 결과 $_totalCount건',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        // 목록
        Expanded(
          child: ListView.separated(
            itemCount:
                _results.length + (_hasMorePages ? 1 : 0),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (ctx, idx) {
              if (idx == _results.length) {
                // 더 보기 버튼
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => _search(page: _currentPage + 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _purple,
                      side: const BorderSide(color: _purple),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('더 보기'),
                  ),
                );
              }
              return _AddressItem(
                item: _results[idx],
                onTap: () => _selectAddress(_results[idx]),
              );
            },
          ),
        ),
      ],
    );
  }

  bool get _hasMorePages =>
      _totalCount > _currentPage * _perPage;
}

// ── 주소 항목 카드 ──
class _AddressItem extends StatelessWidget {
  final _JusoItem item;
  final VoidCallback onTap;

  const _AddressItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded,
                  size: 16, color: Color(0xFF6A1B9A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 도로명 주소 (메인)
                  if (item.roadAddr.isNotEmpty)
                    Text(
                      item.roadAddr,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A)),
                    ),
                  // 건물명
                  if (item.bdNm.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(item.bdNm,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  // 지번 주소 (보조)
                  if (item.jibunAddr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('지번',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF888888),
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(item.jibunAddr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888))),
                          ),
                        ],
                      ),
                    ),
                  // 우편번호
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '[${item.zipNo}]',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
