import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/providers.dart';
import '../../utils/app_localizations.dart';
import '../../models/models.dart';
import '../../services/payment_service.dart';
import '../../services/order_service.dart';
import '../../widgets/pc_layout.dart';
import '../main_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    // PC 웹이면 PC 전용 레이아웃 사용
    if (isPcWeb(context)) {
      return Consumer<CartProvider>(
        builder: (context, cart, _) => Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111111),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Consumer<LanguageProvider>(
              builder: (_, lp, __) => Text(
                '${lp.loc.cart} (${cart.itemCount})',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            actions: [
              if (!cart.isEmpty)
                TextButton(
                  onPressed: () => _showClearDialog(context, cart),
                  child: Consumer<LanguageProvider>(
                    builder: (_, lp, __) => Text(
                      lp.loc.deleteSelected,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
          body: cart.isEmpty
              ? _buildEmptyCart(context)
              : _buildPcLayout(context, cart),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer2<CartProvider, LanguageProvider>(
          builder: (context, cart, lp, _) => Text(
            '${lp.loc.cart} (${cart.itemCount})',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _showClearDialog(context, cart),
                child: Consumer<LanguageProvider>(
                  builder: (_, lp, __) => Text(
                    lp.loc.deleteSelected,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return _buildEmptyCart(context);
          return Column(
            children: [
              // 상단 안내 바
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Text(loc.cartOrderSelectedNote,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) =>
                      _buildCartItem(context, cart, cart.items[index]),
                ),
              ),
              _buildSummary(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPcLayout(BuildContext context, CartProvider cart) {
    final loc = context.watch<LanguageProvider>().loc;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: 장바구니 아이템 목록
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(loc.cartLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
                                child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...cart.items.map((item) => _buildCartItem(context, cart, item)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // 오른쪽: 주문 요약
                SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.cartOrderSummary, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        _pcSummaryRow(loc.cartSubtotal, '${_formatPrice(cart.subtotal)}${loc.wonUnit2}'),
                        _pcSummaryRow(loc.cartShipping, cart.subtotal >= 300000 ? loc.cartFreeShipNone : loc.cartShippingFee),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.cartTotal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Text(
                              '${_formatPrice(cart.total)}${loc.wonUnit2}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(loc.cartCheckout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _pcInfoChip(Icons.local_shipping_outlined, loc.cartFreeShipNote),
                        const SizedBox(height: 8),
                        _pcInfoChip(Icons.replay_rounded, loc.cartExchangeNote),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pcSummaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _pcInfoChip(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 14, color: const Color(0xFF888888)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
    ],
  );

  Widget _buildEmptyCart(BuildContext context) {
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.border),
          const SizedBox(height: 20),
          Consumer<LanguageProvider>(
            builder: (_, lp, __) => Text(
              lp.loc.cartEmpty,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<LanguageProvider>(
            builder: (_, lp, __) => Text(
              lp.loc.cartEmptySub,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Consumer<LanguageProvider>(
                builder: (_, lp, __) => Text(lp.loc.keepShopping),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cart, CartItem item) {
    final langProvider = context.watch<LanguageProvider>();
    final loc = langProvider.loc;
    final lang = langProvider.language;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.product.images.isNotEmpty
                    ? Image.network(
                        item.product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.background,
                          child: const Icon(Icons.image_outlined),
                        ),
                      )
                    : Container(color: AppColors.background),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.localizedName(lang),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.textHint),
                        onPressed: () => cart.removeItem(item.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _optionChip(item.selectedSize),
                      const SizedBox(width: 6),
                      _optionChip(item.selectedColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatPrice(item.unitPrice)}${loc.wonUnit2}', // extraPrice 포함한 단가
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      _buildQtyControl(cart, item),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${loc.cartSubtotalAmount} ${_formatPrice(item.totalPrice)}${loc.wonUnit2}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
    );
  }

  Widget _buildQtyControl(CartProvider cart, CartItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(Icons.remove,
              () => cart.updateQuantity(item.id, item.quantity - 1)),
          SizedBox(
            width: 36,
            child: Center(
              child: Text('${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          _qtyButton(
              Icons.add, () => cart.updateQuantity(item.id, item.quantity + 1)),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 14),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<LanguageProvider>(
                builder: (_, lp, __) => Text(lp.loc.subtotal,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              Text('${_formatPrice(cart.subtotal)}${loc.wonUnit2}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<LanguageProvider>(
                builder: (_, lp, __) => Text(lp.loc.shippingFee,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              Row(
                children: [
                  if (cart.shippingFee == 0) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(loc.cartFreeShipNote, style: const TextStyle(fontSize: 9, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                    ),
                  ],
                  Text(
                    cart.shippingFee == 0 ? loc.cartFreeShipNone : '${_formatPrice(cart.shippingFee)}${loc.wonUnit2}',
                    style: TextStyle(
                      fontWeight: cart.shippingFee == 0 ? FontWeight.w700 : FontWeight.normal,
                      color: cart.shippingFee == 0 ? AppColors.success : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ── 무료배송 진행바 ──
          const SizedBox(height: 8),
          Builder(builder: (ctx) {
            const threshold = 300000.0;
            final sub = cart.subtotal;
            final progress = (sub / threshold).clamp(0.0, 1.0);
            final remaining = (threshold - sub).clamp(0.0, threshold);
            final isFree = cart.shippingFee == 0;
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFree
                    ? const Color(0xFF43A047).withValues(alpha: 0.06)
                    : const Color(0xFF1565C0).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFree
                      ? const Color(0xFF43A047).withValues(alpha: 0.25)
                      : const Color(0xFF1565C0).withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isFree ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                        size: 13,
                        color: isFree ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isFree
                              ? loc.cartFreeShipAchieved
                              : '${_formatPrice(remaining.toDouble())}${loc.cartFreeShipProgress}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isFree ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFree ? const Color(0xFF43A047) : const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<LanguageProvider>(
                builder: (_, lp, __) => Text(lp.loc.totalAmount,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text(
                '${_formatPrice(cart.total)}${loc.wonUnit2}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _showCheckoutSheet(context, cart),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text(
                '${cart.itemCount}${loc.cartItemCount}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, CartProvider cart) {
    final loc = context.read<LanguageProvider>().loc;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.cartClearTitle),
        content: Text(loc.cartClearContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cartCancel)),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.cartDelete),
          ),
        ],
      ),
    );
  }

  void _showCheckoutSheet(BuildContext context, CartProvider cart) {
    // 로그인 체크
    final user = context.read<UserProvider>().user;
    final loc  = context.read<LanguageProvider>().loc;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.loginRequired),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: loc.login,
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CheckoutSheet(cart: cart),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  결제/주문 시트
// ─────────────────────────────────────────────────────────────────
class _CheckoutSheet extends StatefulWidget {
  final CartProvider cart;
  const _CheckoutSheet({required this.cart});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedPayment;   // null → build 시점에 loc 값으로 초기화
  bool   _isProcessing    = false;

  @override
  void initState() {
    super.initState();
    // 로그인된 사용자 정보 자동 채우기 + 결제수단 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<UserProvider>().user;
      final l = context.read<LanguageProvider>().loc;
      if (user != null) {
        _nameCtrl.text  = user.name;
        _phoneCtrl.text = user.phone;
      }
      setState(() => _selectedPayment = l.checkoutKakaoPayMethod);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _fmt(double price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final loc = langProvider.loc;
    final lang = langProvider.language;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 핸들바 ──
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── 헤더 ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.checkoutTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── 스크롤 영역 ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('📦 ${loc.checkoutShippingInfo}'),
                    const SizedBox(height: 10),
                    _buildTextField(_nameCtrl, '${loc.checkoutRecipient} *', Icons.person_outline),
                    const SizedBox(height: 10),
                    _buildTextField(_phoneCtrl, '${loc.checkoutPhoneLabel} * (010-0000-0000)',
                        Icons.phone_outlined,
                        type: TextInputType.phone),
                    const SizedBox(height: 10),
                    _buildTextField(_addressCtrl, '${loc.checkoutAddressLabel} *', Icons.location_on_outlined),
                    const SizedBox(height: 24),
                    _sectionTitle('💳 ${loc.payMethod}'),
                    const SizedBox(height: 12),
                    _buildPaymentMethods(),
                    const SizedBox(height: 24),
                    _sectionTitle('🧾 ${loc.checkoutOrderedItems}'),
                    const SizedBox(height: 10),
                    ...widget.cart.items.map((item) => _buildOrderItem(item, lang)),
                    const SizedBox(height: 16),
                    _buildPriceSummary(),
                    const SizedBox(height: 8),
                    // 무통장 안내
                    if (_selectedPayment == loc.checkoutBankMethod && _selectedPayment != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFCC02)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.bankTransferGuide,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(loc.bankAccount,
                                style: const TextStyle(fontSize: 12)),
                            Text(loc.bankTransferDeadline,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // ── 결제 버튼 ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          '${_fmt(widget.cart.total)}${loc.wonUnit2} ${loc.cartCheckoutBtn}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {'id': loc.checkoutKakaoPayMethod, 'icon': '💛', 'label': loc.checkoutKakaoPayMethod},
      {'id': loc.checkoutTossPayMethod, 'icon': '💙', 'label': loc.checkoutTossPayMethod},
      {'id': loc.checkoutNaverPayMethod, 'icon': '💚', 'label': loc.checkoutNaverPayMethod},
      {'id': loc.checkoutCardMethod, 'icon': '💳', 'label': loc.checkoutCardMethod},
      {'id': loc.checkoutBankMethod, 'icon': '🏦', 'label': loc.checkoutBankMethod},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final isSelected = _selectedPayment == m['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPayment = m['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m['icon']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  m['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderItem(CartItem item, AppLanguage lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.product.images.isNotEmpty
                  ? Image.network(item.product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: AppColors.background,
                            child: const Icon(Icons.image_outlined, size: 20),
                          ))
                  : Container(color: AppColors.background),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.localizedName(lang),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    softWrap: true),
                Text(
                  '${item.selectedSize} / ${item.selectedColor} × ${item.quantity}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${_fmt(item.totalPrice)}${loc.wonUnit2}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _priceRow(loc.cartProductAmount, widget.cart.subtotal),
          const SizedBox(height: 6),
          _priceRow(loc.cartShipping,
              widget.cart.shippingFee,
              free: widget.cart.shippingFee == 0),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<LanguageProvider>(
                builder: (ctx, lp, _) => Text(lp.loc.totalAmount,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Text(
                '${_fmt(widget.cart.total)}${loc.wonUnit2}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool free = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(
          free ? loc.cartFreeShip : '${_fmt(amount)}${loc.wonUnit2}',
          style: TextStyle(
              fontSize: 13,
              color: free ? AppColors.success : AppColors.textPrimary),
        ),
      ],
    );
  }

  // ─── 실제 결제 처리 ──────────────────────────────────────────────
  Future<void> _processPayment() async {
    // 0. 결제수단 미선택 체크
    if (_selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.checkoutSelectPayment),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // 1. 입력 검증
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.cartShippingInfoRequired),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userProv  = context.read<UserProvider>();
      final orderProv = context.read<OrderProvider>();
      final user      = userProv.user;

      // 2. 주문번호 생성
      final orderId = OrderService.generateOrderId();

      // 3. 무통장입금 → 바로 주문 저장
      if (_selectedPayment == loc.checkoutBankMethod) {
        await _saveAndComplete(
          orderId:    orderId,
          orderProv:  orderProv,
          userProv:   userProv,
          paid:       false,
          payMethod:  loc.checkoutBankMethod,
        );
        return;
      }

      // 4. 토스페이먼츠 결제창 호출
      if (!mounted) return;
      final result = await PaymentService.requestPayment(
        context,
        orderId:       orderId,
        orderName:     '2FIT MALL 주문 (${widget.cart.itemCount}개)',
        amount:        widget.cart.total.toInt(),
        customerName:  _nameCtrl.text.trim(),
        customerEmail: user?.email ?? 'guest@2fit-mall.co.kr',
        paymentMethod: _selectedPayment!,
      );

      if (!mounted) return;

      if (result.success) {
        // 5. 결제 성공 → 주문 저장
        await _saveAndComplete(
          orderId:    orderId,
          orderProv:  orderProv,
          userProv:   userProv,
          paid:       true,
          payMethod:  _selectedPayment!,
          paymentKey: result.paymentKey,
        );
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? loc.paymentCancelled),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.paymentError(e.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveAndComplete({
    required String       orderId,
    required OrderProvider orderProv,
    required UserProvider  userProv,
    required bool          paid,
    required String        payMethod,
    String?                paymentKey,
  }) async {
    final user = userProv.user;

    // OrderItem 리스트 변환
    final orderItems = widget.cart.items.map((c) => OrderItem(
      productId:   c.product.id,
      productName: c.product.name,
      size:        c.selectedSize,
      color:       c.selectedColor,
      quantity:    c.quantity,
      price:       c.product.price,
    )).toList();

    final order = OrderModel(
      id:          orderId,
      userId:      user?.id ?? 'guest',
      userName:    _nameCtrl.text.trim(),
      userPhone:   _phoneCtrl.text.trim(),
      userAddress: _addressCtrl.text.trim(),
      status:      paid ? OrderStatus.confirmed : OrderStatus.pending,
      totalAmount: widget.cart.total,
      shippingFee: widget.cart.shippingFee,
      paymentMethod: payMethod,
      orderType:   'regular',
      createdAt:   DateTime.now(),
      items:       orderItems,
    );

    // Hive에 영구 저장
    await OrderService.saveOrder(order);

    // Provider에도 추가 (실시간 반영)
    orderProv.addOrder(order);

    // 포인트 적립 (결제금액의 1%)
    if (paid && user != null) {
      final earnedPoints = (widget.cart.total * 0.01).toInt();
      userProv.addPoints(earnedPoints);
    }

    // 장바구니 비우기
    widget.cart.clearCart();

    if (!mounted) return;
    Navigator.pop(context); // 바텀시트 닫기

    // 주문완료 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OrderCompleteDialog(
        orderId:     orderId,
        total:       order.totalAmount,
        shippingFee: order.shippingFee,
        payMethod:   payMethod,
        paid:        paid,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  주문완료 다이얼로그
// ─────────────────────────────────────────────────────────────────
class _OrderCompleteDialog extends StatelessWidget {
  final String orderId;
  final double total;
  final double shippingFee;
  final String payMethod;
  final bool   paid;

  const _OrderCompleteDialog({
    required this.orderId,
    required this.total,
    required this.shippingFee,
    required this.payMethod,
    required this.paid,
  });

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 성공 아이콘
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(loc.orderComplete2,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              paid ? loc.orderCompleteMsg : loc.bankTransferDeadline,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // 주문 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(loc.mypageOrderId, orderId),
                  const SizedBox(height: 6),
                  _infoRow(loc.payMethod, payMethod),
                  const SizedBox(height: 6),
                  _infoRow(loc.checkoutPaymentInfo, paid ? '✅ ${loc.checkoutPaymentApproved}' : '⏳ ${loc.checkoutPaymentPending}'),
                  const SizedBox(height: 6),
                  _infoRow(loc.cartPayAmount, '${_fmt(total)}${loc.wonUnit2}'),
                  if (shippingFee == 0) ...[
                    const SizedBox(height: 6),
                    _infoRow(loc.cartShipping, '무료'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 포인트 적립 안내
            if (paid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '${(total * 0.01).toInt()}P ${loc.mypagePointsEarned}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.continueShopping),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // MainScreen의 마이페이지(인덱스 4)로 이동
                      final mainState = context.findAncestorStateOfType<MainScreenState>();
                      mainState?.navigateToMyPage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.orderHistory,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


