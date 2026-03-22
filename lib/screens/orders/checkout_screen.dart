import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/fcm_service.dart';
import '../main_screen.dart';
import '../../widgets/kakao_address_search.dart';
import '../../widgets/pc_layout.dart';

class CheckoutScreen extends StatefulWidget {
  final CartProvider cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = '카카오페이';
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _memoController = TextEditingController();
  final _couponCodeController = TextEditingController();
  // 해외 주소 전용 컨트롤러
  final _intlLine1Ctrl   = TextEditingController(); // Street address
  final _intlLine2Ctrl   = TextEditingController(); // Apt/Suite (선택)
  final _intlCityCtrl    = TextEditingController(); // City
  final _intlStateCtrl   = TextEditingController(); // State/Province
  final _intlZipCtrl     = TextEditingController(); // ZIP/Postal code
  final _intlCountryCtrl = TextEditingController(); // Country
  bool _isProcessing = false;
  bool _isOverseas = false;   // false=국내, true=해외
  String _zonecode = '';

  CouponModel? _appliedCoupon;

  // 번역 헬퍼
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _addressController.text = user.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _detailAddressController.dispose();
    _memoController.dispose();
    _couponCodeController.dispose();
    _intlLine1Ctrl.dispose();
    _intlLine2Ctrl.dispose();
    _intlCityCtrl.dispose();
    _intlStateCtrl.dispose();
    _intlZipCtrl.dispose();
    _intlCountryCtrl.dispose();
    super.dispose();
  }

  double get _couponDiscount =>
      _appliedCoupon?.calculateDiscount(widget.cart.subtotal) ?? 0;
  double get _finalTotal =>
      (widget.cart.total - _couponDiscount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.checkoutPayment),
        backgroundColor: AppColors.primary,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrdererInfo(),
                  const SizedBox(height: 16),
                  _buildShippingInfo(),
                  const SizedBox(height: 16),
                  _buildOrderItems(),
                  const SizedBox(height: 16),
                  _buildCouponSection(),
                  const SizedBox(height: 16),
                  _buildPaymentMethod(),
                  const SizedBox(height: 16),
                  _buildPriceSummary(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── PC 전용 2컬럼 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(loc.checkoutPayment),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 좌측: 주문 입력 정보 ──
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildOrdererInfo(),
                        const SizedBox(height: 16),
                        _buildShippingInfo(),
                        const SizedBox(height: 16),
                        _buildOrderItems(),
                        const SizedBox(height: 16),
                        _buildCouponSection(),
                        const SizedBox(height: 16),
                        _buildPaymentMethod(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // ── 우측: 주문 요약 + 결제 버튼 ──
                SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPriceSummary(),
                      const SizedBox(height: 16),
                      // 결제 버튼 (PC에서는 사이드에 위치)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10, offset: const Offset(0, 2),
                          )],
                        ),
                        child: Column(
                          children: [
                            Text(
                              loc.checkoutAgree,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _processPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        '$_selectedPayment\n${_formatPrice(_finalTotal)}원 결제',
                                        style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 13, color: Color(0xFF888888)),
                                const SizedBox(width: 4),
                                Text(context.watch<LanguageProvider>().loc.sslSecure,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                                const SizedBox(width: 12),
                                const Icon(Icons.replay_rounded,
                                    size: 13, color: Color(0xFF888888)),
                                const SizedBox(width: 4),
                                Text(context.watch<LanguageProvider>().loc.returnIn7Days,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdererInfo() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return _buildSection(
      loc.checkoutOrdererInfo,
      Column(
        children: [
          _buildInfoRow(loc.checkoutNameLabel, user?.name ?? ''),
          _buildInfoRow(loc.checkoutPhoneLabel, user?.phone ?? ''),
          _buildInfoRow(loc.checkoutEmailLabel, user?.email ?? ''),
        ],
      ),
    );
  }

  Future<void> _searchAddress() async {
    final result = await showKakaoAddressSearch(context);
    if (result != null) {
      setState(() {
        _zonecode = result.zonecode;
        _addressController.text = result.address;
      });
      FocusScope.of(context).nextFocus();
    }
  }

  // 최종 주소 문자열 조합
  String get _finalAddress {
    if (_isOverseas) {
      final parts = [
        _intlLine1Ctrl.text.trim(),
        if (_intlLine2Ctrl.text.trim().isNotEmpty) _intlLine2Ctrl.text.trim(),
        _intlCityCtrl.text.trim(),
        if (_intlStateCtrl.text.trim().isNotEmpty) _intlStateCtrl.text.trim(),
        _intlZipCtrl.text.trim(),
        _intlCountryCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).toList();
      return parts.join(', ');
    } else {
      final base = _addressController.text.trim();
      final detail = _detailAddressController.text.trim();
      return detail.isNotEmpty ? '$base $detail' : base;
    }
  }

  bool get _addressFilled {
    if (_isOverseas) {
      return _intlLine1Ctrl.text.trim().isNotEmpty &&
          _intlCityCtrl.text.trim().isNotEmpty &&
          _intlCountryCtrl.text.trim().isNotEmpty;
    } else {
      return _addressController.text.trim().isNotEmpty;
    }
  }

  Widget _buildShippingInfo() {
    return _buildSection(
      loc.checkoutShippingInfo,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 국내 / 해외 탭 ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _addrTab('🇰🇷  국내 배송', !_isOverseas, () => setState(() {
                  _isOverseas = false;
                })),
                _addrTab('🌏  해외 배송', _isOverseas, () => setState(() {
                  _isOverseas = true;
                })),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 국내 주소 ──
          if (!_isOverseas) ...[
            _buildDomesticAddress(),
          ] else ...[
            _buildOverseasAddress(),
          ],

          const SizedBox(height: 10),
          // ── 배송 메모 ──
          TextFormField(
            controller: _memoController,
            decoration: InputDecoration(
              labelText: loc.checkoutShippingMemo,
              hintText: loc.checkoutShippingMemoHint,
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addrTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? const Color(0xFF1A1A2E) : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }

  // 국내 주소 입력
  Widget _buildDomesticAddress() {
    final hasAddress = _addressController.text.isNotEmpty;
    return Column(
      children: [
        // 카카오 주소 검색 버튼
        GestureDetector(
          onTap: _searchAddress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasAddress ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
                width: hasAddress ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: hasAddress ? const Color(0xFF1A1A2E) : const Color(0xFF999999),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: hasAddress
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_zonecode.isNotEmpty)
                              Text('[$_zonecode]',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0064FF),
                                      fontWeight: FontWeight.w700)),
                            Text(_addressController.text,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E))),
                          ],
                        )
                      : Text(loc.checkoutAddressSearch,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(loc.checkoutSearch,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 상세주소
        TextFormField(
          controller: _detailAddressController,
          decoration: InputDecoration(
            hintText: hasAddress ? loc.checkoutDetailAddressHint : loc.checkoutDetailAddressSearch,
            prefixIcon: const Icon(Icons.home_rounded),
            enabled: hasAddress,
            filled: true,
            fillColor: hasAddress ? Colors.white : const Color(0xFFF5F5F5),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // 해외 주소 입력
  Widget _buildOverseasAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 안내 배너
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.checkoutEnglishAddress,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _intlField('Street Address *', _intlLine1Ctrl,
            hint: '123 Main St', required: true),
        const SizedBox(height: 8),
        _intlField('Apt / Suite / Floor (선택)', _intlLine2Ctrl,
            hint: 'Apt 4B'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _intlField('City *', _intlCityCtrl,
                  hint: 'New York', required: true),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _intlField('State / Province', _intlStateCtrl,
                  hint: 'NY'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _intlField('ZIP / Postal Code', _intlZipCtrl,
                  hint: '10001'),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _intlField('Country *', _intlCountryCtrl,
                  hint: 'United States', required: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _intlField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.replaceAll(' *', ''),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444)),
            children: required
                ? const [TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFFE53935)))]
                : [],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF1A1A2E), width: 2)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return _buildSection(
      loc.orderItemsCount(widget.cart.items.length),
      Column(
        children: widget.cart.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.product.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.background,
                    child: const Icon(Icons.checkroom_rounded, color: AppColors.textHint),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.localizedName(_lang),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                    ),
                    Text(
                      '${item.selectedColor} / ${item.selectedSize} × ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.extraPrice > 0)
                      Text(
                        loc.extraPriceLabel(_formatPrice(item.extraPrice)),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatPrice(item.totalPrice)}원',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (item.extraPrice > 0)
                    Text(
                      '(단가 ${_formatPrice(item.unitPrice)}원)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCouponSection() {
    return _buildSection(
      loc.couponApply,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF43A047)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded,
                      color: Color(0xFF43A047), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_appliedCoupon!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${_formatPrice(_couponDiscount)}${loc.wonUnit} 할인',
                            style: const TextStyle(
                                color: Color(0xFF43A047), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() {
                      _appliedCoupon = null;
                      _couponCodeController.clear();
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: loc.couponInputHint,
                      prefixIcon: const Icon(Icons.discount_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  child: Text(loc.applyBtn, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<CouponProvider>(
              builder: (_, couponProv, __) {
                final valid = couponProv.validCoupons;
                if (valid.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.availableCoupons,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888))),
                    const SizedBox(height: 6),
                    ...valid.map((c) => GestureDetector(
                      onTap: () => setState(() {
                        _appliedCoupon = c;
                        _couponCodeController.text = c.code;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    '${c.typeLabel} | 최소 ${_formatPrice(c.minOrderAmount)}원',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              loc.checkoutCouponApply,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _applyCoupon() {
    final code = _couponCodeController.text.trim();
    if (code.isEmpty) return;
    final couponProv =
        Provider.of<CouponProvider>(context, listen: false);
    final coupon = couponProv.findByCode(code);
    if (coupon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.checkoutCouponInvalid),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
      return;
    }
    if (widget.cart.subtotal < coupon.minOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              loc.minOrderAmountMsg(_formatPrice(coupon.minOrderAmount))),

          backgroundColor: const Color(0xFFE53935),
        ),
      );
      return;
    }
    setState(() => _appliedCoupon = coupon);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.checkoutCouponApplied),
        backgroundColor: const Color(0xFF43A047),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return _buildSection(
      loc.paymentMethod,
      Column(
        children: AppConstants.paymentMethods.map((method) {
          final isSelected = _selectedPayment == method;
          return GestureDetector(
            onTap: () => setState(() => _selectedPayment = method),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  _buildPaymentIcon(method),
                  const SizedBox(width: 8),
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentIcon(String method) {
    IconData icon;
    Color color;
    switch (method) {
      case '카카오페이': // KakaoPay
        icon = Icons.chat_rounded;
        color = const Color(0xFFFFE500);
        break;
      case '신용/체크카드': // Credit card
        icon = Icons.credit_card_rounded;
        color = AppColors.primary;
        break;
      case '무통장입금': // Bank transfer
        icon = Icons.account_balance_rounded;
        color = const Color(0xFF43A047);
        break;
      case '네이버페이': // NaverPay
        icon = Icons.search_rounded;
        color = const Color(0xFF03C75A);
        break;
      default:
        icon = Icons.payment_rounded;
        color = AppColors.accent;
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildPriceSummary() {
    final subtotal = widget.cart.subtotal;
    final shippingFee = widget.cart.shippingFee;
    const threshold = 300000.0;
    final isFreeShipping = shippingFee == 0;
    final remaining = (threshold - subtotal).clamp(0.0, threshold);
    final progress = (subtotal / threshold).clamp(0.0, 1.0);

    return _buildSection(
      loc.paymentAmountTitle,
      Column(
        children: [
          // ── 무료배송 진행바 ──
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFreeShipping
                  ? const Color(0xFF43A047).withValues(alpha: 0.07)
                  : const Color(0xFF1565C0).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFreeShipping
                    ? const Color(0xFF43A047).withValues(alpha: 0.3)
                    : const Color(0xFF1565C0).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isFreeShipping
                          ? Icons.local_shipping_rounded
                          : Icons.local_shipping_outlined,
                      size: 16,
                      color: isFreeShipping
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isFreeShipping
                            ? '🎉 무료배송 조건 달성!'
                            : '${_formatPrice(remaining)}원 더 담으면 무료배송!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFreeShipping
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    Text(
                      loc.freeShippingThreshold,
                      style: TextStyle(
                        fontSize: 10,
                        color: isFreeShipping
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 진행바
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFreeShipping
                          ? const Color(0xFF43A047)
                          : const Color(0xFF1E88E5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.currentAmountLabel(_formatPrice(subtotal)),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                    ),
                    Text(
                      loc.freeShippingThreshold,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildPriceRow(loc.productAmount, subtotal),
          // 배송비 행 (무료배송 시 강조)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.shippingFeeLabel,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
                Row(
                  children: [
                    if (isFreeShipping) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(loc.freeShippingThreshold,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                      ),
                    ],
                    Text(
                      isFreeShipping ? loc.freeLabel : '${_formatPrice(shippingFee)}원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isFreeShipping ? const Color(0xFF43A047) : const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_couponDiscount > 0)
            _buildPriceRow(loc.couponDiscount, -_couponDiscount, isDiscount: true),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.finalPayment,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_formatPrice(_finalTotal)}원',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Text(
              context.watch<LanguageProvider>().loc.checkoutAgree,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primary,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '$_selectedPayment로 ${_formatPrice(_finalTotal)}원 결제하기',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double price,
      {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(
            isDiscount
                ? '-${_formatPrice(-price)}원'
                : price == 0
                    ? loc.checkoutPaymentFree
                    : '${_formatPrice(price)}원',
            style: TextStyle(
              fontSize: 13,
              color: isDiscount
                  ? const Color(0xFF43A047)
                  : price == 0
                      ? const Color(0xFF43A047)
                      : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 결제하기 버튼 클릭 ─────────────────────────────────────
  void _processPayment() async {
    // 주소 미입력 체크
    if (!_addressFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOverseas
              ? 'Street Address, City, Country는 필수입니다.'
              : loc.checkoutNoAddress),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final orderId = 'ORD-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2,'0')}${DateTime.now().day.toString().padLeft(2,'0')}-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5,'0')}';

    // 결제 다이얼로그 표시
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TossPaymentDialog(
        orderId: orderId,
        orderName: widget.cart.items.first.product.name +
            (widget.cart.items.length > 1
                ? ' 외 ${widget.cart.items.length - 1}건'
                : ''),
        amount: _finalTotal.toInt(),
        customerName: user?.name ?? loc.buyerLabel,
        paymentMethod: _selectedPayment,
      ),
    );

    if (!mounted) return;
    if (result != true) return;

    // 결제 승인 후 주문 저장
    setState(() => _isProcessing = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = OrderModel(
      id: orderId,
      userId: user?.id ?? 'guest',
      userName: user?.name ?? '',
      userEmail: user?.email ?? '',
      userPhone: user?.phone ?? '',
      userAddress: _finalAddress,
      items: widget.cart.items.map((item) => OrderItem(
        productId: item.product.id,
        productName: item.product.name,
        size: item.selectedSize,
        color: item.selectedColor,
        quantity: item.quantity,
        price: item.product.price,
      )).toList(),
      totalAmount: _finalTotal,
      shippingFee: widget.cart.shippingFee,
      paymentMethod: _selectedPayment,
      createdAt: DateTime.now(),
      memo: _memoController.text,
    );
    orderProvider.addOrder(order);
    // 신규 주문 FCM 알림 (관리자에게)
    FcmService.sendNewOrderNotification(order).catchError(
      (e) { /* 알림 실패해도 주문은 진행 */ },
    );

    // 쿠폰 사용 처리
    if (_appliedCoupon != null) {
      Provider.of<CouponProvider>(context, listen: false)
          .useCoupon(_appliedCoupon!.id);
    }

    // 앱 내 알림
    Provider.of<NotificationProvider>(context, listen: false).addNotification(
      NotificationModel(
        id: 'n_$orderId',
        title: loc.orderCompletedTitle,
        body: '${loc.checkoutOrderNum}: $orderId',
        type: 'order',
        createdAt: DateTime.now(),
      ),
    );

    widget.cart.clearCart();
    setState(() => _isProcessing = false);

    // 주문완료 화면으로 이동
    if (mounted) {
      _showOrderCompleteScreen(order);
    }
  }

  // ─── 주문완료 전체화면 ────────────────────────────────────────
  void _showOrderCompleteScreen(OrderModel order) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _OrderCompleteScreen(
          order: order,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ══════════════════════════════════════════════════════════════
// 토스페이먼츠 결제 다이얼로그 (실제 쇼핑몰 UI)
// ══════════════════════════════════════════════════════════════
class _TossPaymentDialog extends StatefulWidget {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String paymentMethod;

  const _TossPaymentDialog({
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
    required this.paymentMethod,
  });

  @override
  State<_TossPaymentDialog> createState() => _TossPaymentDialogState();
}

class _TossPaymentDialogState extends State<_TossPaymentDialog> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  // 단계: 0=입력, 1=처리중, 2=완료, 3=실패
  int _step = 0;
  String? _errorMsg;

  // 카드 입력 컨트롤러
  final _cardNumCtrl  = TextEditingController(text: '4330-0000-0000-0000');
  final _expiryCtrl   = TextEditingController(text: '12/26');
  final _pwCtrl       = TextEditingController(text: '00');
  final _birthCtrl    = TextEditingController(text: '000101');

  @override
  void dispose() {
    _cardNumCtrl.dispose();
    _expiryCtrl.dispose();
    _pwCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  String get _amtFmt => widget.amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  Future<void> _pay() async {
    setState(() { _step = 1; _errorMsg = null; });

    // 실제 결제 승인 시뮬레이션 (토스 API 연동 시 여기서 호출)
    await Future.delayed(const Duration(milliseconds: 1800));

    // 테스트: 카드번호가 올바른 테스트 번호면 성공
    final cardNum = _cardNumCtrl.text.replaceAll('-', '').replaceAll(' ', '');
    if (cardNum.length == 16) {
      setState(() => _step = 2);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _step = 3;
        _errorMsg = loc.checkoutCardInvalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildOrderSummary(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                key: ValueKey(_step),
                padding: const EdgeInsets.all(20),
                child: _step == 1
                    ? _buildProcessing()
                    : _step == 2
                        ? _buildSuccess()
                        : _buildCardForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0064FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.checkoutTestPayment,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('TEST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
          if (_step == 0) ...[ 
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            ),
          ],
        ],
      ),
    );
  }

  // 주문 요약
  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFF8F9FA),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.orderName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(widget.orderId,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$_amtFmt${loc.wonUnit}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  // 카드 입력 폼
  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 테스트 안내 배너
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD54F)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF57F17)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.testPaymentNotice,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFF57F17), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 결제수단 뱃지
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0064FF), width: 1.5),
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFF0F5FF),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card_rounded, color: Color(0xFF0064FF), size: 22),
              const SizedBox(width: 10),
              Text(
                widget.paymentMethod,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF0064FF), fontSize: 14),
              ),
              const Spacer(),
              const Text('Visa / Master', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 카드번호
        _buildField(loc.checkoutCardNumberLabel, _cardNumCtrl, hint: '1234-5678-9012-3456', keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildField(loc.checkoutExpiryLabel, _expiryCtrl, hint: 'MM/YY')),
            const SizedBox(width: 10),
            Expanded(child: _buildField(loc.checkoutPwLabel, _pwCtrl, hint: '••', obscure: true)),
          ],
        ),
        const SizedBox(height: 10),
        _buildField(loc.checkoutBirthLabel, _birthCtrl, hint: 'YYMMDD', keyboardType: TextInputType.number),

        if (_errorMsg != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMsg!,
                      style: const TextStyle(color: Color(0xFFE53935), fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // 결제 버튼
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0064FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '$_amtFmt원 결제하기',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // 결제중 화면
  Widget _buildProcessing() {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              color: Color(0xFF0064FF), strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(loc.checkoutProcessing, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(loc.checkoutPleaseWait, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  // 결제완료 화면
  Widget _buildSuccess() {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          Text(loc.checkoutPaymentApproved,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(loc.checkoutOrderReceived, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0064FF), width: 2)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 주문완료 전체화면
// ══════════════════════════════════════════════════════════════
class _OrderCompleteScreen extends StatelessWidget {
  final OrderModel order;

  const _OrderCompleteScreen({required this.order});

  String _fmt(double v) => v.toInt().toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── 상단 완료 배너 ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853), shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(loc.checkoutOrderComplete,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.id,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 주문 상품 목록 ──
              _card(
                title: loc.checkoutOrderedItems,
                child: Column(
                  children: order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.checkroom_rounded,
                              color: Color(0xFF999999), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${item.color} / ${item.size} · ${item.quantity}개',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF888888)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_fmt(item.price * item.quantity)}원',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // ── 배송 정보 ──
              _card(
                title: loc.checkoutShippingInfo,
                child: Column(
                  children: [
                    _infoRow(loc.checkoutRecipient, order.userName),
                    _infoRow(loc.checkoutPhoneLabel, order.userPhone),
                    _infoRow(loc.checkoutAddressLabel, order.userAddress, multiLine: true),
                    if (order.memo != null && order.memo!.isNotEmpty)
                      _infoRow(loc.checkoutDeliveryMemo, order.memo!),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── 결제 정보 ──
              _card(
                title: loc.checkoutPaymentInfo,
                child: Column(
                  children: [
                    _priceRow(loc.productAmount, order.totalAmount + (order.shippingFee) - order.shippingFee),
                    _priceRow(loc.cartShipping,
                        order.shippingFee,
                        sub: order.shippingFee == 0 ? loc.checkoutPaymentFree : null),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.cartTotal,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(
                          '${_fmt(order.totalAmount)}원',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.payMethod,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                        Text(order.paymentMethod,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── 배송 안내 ──
              _card(
                title: loc.checkoutDeliveryGuide,
                child: Column(
                  children: [
                    _guideRow(Icons.schedule_rounded, loc.checkoutDeliveryDays),
                    _guideRow(Icons.local_shipping_rounded, 'CJ대한통운 · 배송조회는 마이페이지에서'),
                    _guideRow(Icons.support_agent_rounded, loc.checkoutKakaoInquiry),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 버튼 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                          final ms = context.findAncestorStateOfType<MainScreenState>();
                          ms?.navigateTo(3);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(loc.checkoutViewOrders,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(loc.checkoutShopContinue,
                            style: const TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double price, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          Text(
            sub ?? '${_fmt(price)}원',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: sub != null ? const Color(0xFF43A047) : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF888888)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
          ),
        ],
      ),
    );
  }
}
