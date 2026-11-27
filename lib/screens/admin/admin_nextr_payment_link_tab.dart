// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/nextr_payment_link_service.dart';
import '../../services/product_service.dart';
import '../../utils/theme.dart';
import '../../widgets/address_search_widget.dart';

class AdminNextrPaymentLinkTab extends StatefulWidget {
  const AdminNextrPaymentLinkTab({super.key});
  @override
  State<AdminNextrPaymentLinkTab> createState() =>
      _AdminNextrPaymentLinkTabState();
}

class _AdminNextrPaymentLinkTabState extends State<AdminNextrPaymentLinkTab> {
  final _product = TextEditingController();
  final _qty = TextEditingController(text: '5');
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _memo = TextEditingController();
  List<Map<String, dynamic>> _links = [];
  List<ProductModel> _products = [];
  bool _loading = false;
  bool _productsLoading = true;
  String? _createdUrl;
  String? _selectedProductId;
  @override
  void initState() {
    super.initState();
    _load();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final c in [_product, _qty, _name, _phone, _address, _memo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await NextrPaymentLinkService.list();
      if (mounted) setState(() => _links = items);
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.getAllProductsForAdmin();
      if (mounted) {
        setState(() {
          _products = products;
          _productsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _productsLoading = false);
    }
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final result = await NextrPaymentLinkService.create(
          productId: _product.text.trim(),
          quantity: int.tryParse(_qty.text) ?? 0,
          customerName: _name.text.trim(),
          customerPhone: _phone.text.trim(),
          deliveryAddress: _address.text.trim(),
          memo: _memo.text.trim());
      if (mounted) {
        setState(() => _createdUrl = result['url'] as String?);
        await Clipboard.setData(ClipboardData(text: _createdUrl ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('결제 링크를 생성하고 클립보드에 복사했습니다.')));
        _load();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(dynamic v) => '${(v as num? ?? 0).toInt()}'
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      isDense: true);
  Widget _field(TextEditingController c, String label,
          {String? hint, TextInputType? type, int? maxLines}) =>
      TextField(
          controller: c,
          keyboardType: type,
          maxLines: maxLines,
          decoration: _dec(label, hint: hint));

  Widget _addressField() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _field(_address, '배송지',
                hint: '주소 검색 후 상세주소를 입력하세요', maxLines: 2),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await showAddressSearch(context);
                if (!mounted || result == null) return;
                setState(() {
                  _address.text = result.zonecode.isEmpty
                      ? result.address
                      : '[${result.zonecode}] ${result.address}';
                  _address.selection = TextSelection.fromPosition(
                    TextPosition(offset: _address.text.length),
                  );
                });
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('주소 검색'),
            ),
          ),
        ],
      );

  Widget _productSelector() {
    if (_productsLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: '상품 선택',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    return Autocomplete<ProductModel>(
      displayStringForOption: (product) => product.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return _products;
        return _products.where((product) {
          return product.name.toLowerCase().contains(query) ||
              product.productCode.toLowerCase().contains(query) ||
              product.id.toLowerCase().contains(query);
        });
      },
      onSelected: (product) {
        setState(() {
          _product.text = product.id;
          _selectedProductId = product.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} 상품이 선택되었습니다.')));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: _dec(
            '상품 선택',
            hint: '상품명·상품번호로 검색 후 선택하세요',
          ).copyWith(prefixIcon: const Icon(Icons.search_rounded)),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final product = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(product.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      product.productCode.isEmpty
                          ? '상품 ID: ${product.id}'
                          : '상품번호: ${product.productCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelected(product),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMemberLinkDialog(Map<String, dynamic> link) async {
    final orderId = (link['orderId'] as String? ?? '').trim();
    if (orderId.isEmpty) return;
    final query = TextEditingController();
    List<Map<String, dynamic>> members = [];
    bool loading = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('주문 회원 연결'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('주문번호: $orderId', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: query,
                  decoration: InputDecoration(
                    labelText: '회원명·이메일·연락처',
                    suffixIcon: IconButton(
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      onPressed: loading
                          ? null
                          : () async {
                              if (query.text.trim().length < 2) return;
                              setDialogState(() => loading = true);
                              try {
                                final result =
                                    await NextrPaymentLinkService.searchMembers(
                                        query.text.trim());
                                if (context.mounted) {
                                  setDialogState(() => members = result);
                                }
                              } finally {
                                if (context.mounted) {
                                  setDialogState(() => loading = false);
                                }
                              }
                            },
                    ),
                  ),
                  onSubmitted: (_) async {
                    if (query.text.trim().length < 2 || loading) return;
                    setDialogState(() => loading = true);
                    try {
                      final result =
                          await NextrPaymentLinkService.searchMembers(
                              query.text.trim());
                      if (context.mounted)
                        setDialogState(() => members = result);
                    } finally {
                      if (context.mounted) {
                        setDialogState(() => loading = false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  const Text('검색 결과가 여기에 표시됩니다.',
                      style: TextStyle(color: AppColors.textSecondary))
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final member = members[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline),
                          title: Text(member['name'] as String? ?? '회원'),
                          subtitle: Text(
                              '${member['email'] ?? ''} · ${member['phone'] ?? ''}'),
                          trailing: const Icon(Icons.link_rounded),
                          onTap: () async {
                            setDialogState(() => loading = true);
                            try {
                              await NextrPaymentLinkService.linkOrderToMember(
                                orderId: orderId,
                                userId: member['uid'] as String,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(dialogContext);
                              _load();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${member['name'] ?? '회원'}님에게 주문을 연결했습니다.')),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                setDialogState(() => loading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e
                                          .toString()
                                          .replaceFirst('Exception: ', ''))),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('닫기')),
          ],
        ),
      ),
    );
    query.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
      color: AppColors.background,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('NEXTR 카드 결제 링크',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _productSelector(),
                  if (_selectedProductId != null)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          '상품 문서 ID가 자동 입력되었습니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  _field(_qty, '수량', type: TextInputType.number),
                  const SizedBox(height: 10),
                  _field(_name, '고객명'),
                  const SizedBox(height: 10),
                  _field(_phone, '연락처', type: TextInputType.phone),
                  const SizedBox(height: 10),
                  _addressField(),
                  const SizedBox(height: 10),
                  _field(_memo, '메모(선택)'),
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                          onPressed: _loading ? null : _create,
                          child: Text(_loading ? '생성 중...' : '카드 결제 링크 생성'))),
                  if (_createdUrl != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(_createdUrl!,
                        style: const TextStyle(color: AppColors.primary))
                  ],
                ]))),
        const SizedBox(height: 22),
        const Text('최근 생성 링크',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._links.map((link) => Card(
            child: ListTile(
                title: Text('${link['productName']} · ${link['quantity']}장'),
                subtitle: Text(
                    '${link['customerName']} · ${_money(link['amount'])}원 · ${link['status']}${link['linkedUserId'] != null ? ' · 회원 연결됨' : ''}'),
                trailing: link['status'] == 'active'
                    ? IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () async {
                          await NextrPaymentLinkService.cancel(
                              link['linkId'] as String);
                          _load();
                        })
                    : null,
                onTap: () {
                  if ((link['orderId'] as String? ?? '').isNotEmpty &&
                      link['linkedUserId'] == null) {
                    _showMemberLinkDialog(link);
                  } else {
                    Clipboard.setData(
                        ClipboardData(text: link['linkId'] as String));
                  }
                }))),
      ]));
}
