import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'net_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/products/product_detail_screen.dart';

// ignore: unused_import
import '../utils/app_localizations.dart';

/// 공유 상품 카드 — 홈화면 단체주문 카드와 동일한 스타일
/// · 이미지 4:5 비율 / BoxFit.cover (이미지 꽉 채움)
/// · 좌상단: NEW / SALE / GROUP 배지
/// · 우상단: 할인율 배지 (있을 때만)
/// · 하단: [단체주문 전용 뱃지] → 상품명 → 가격
class ProductCard extends StatelessWidget {
  final ProductModel product;
  /// true = 카드 너비가 외부(ListView)에서 결정됨 (가로 스크롤용)
  /// false = GridView 셀 크기에 맞게 채움 (기본)
  final bool isHorizontal;
  /// false로 넘기면 _buildInfo()의 "단체주문 전용" 텍스트 배지를 숨김
  /// (홈화면 단체주문 전용 섹션 카드에서 중복 표시 방지)
  final bool showGroupBadge;

  const ProductCard({super.key, required this.product, this.isHorizontal = false, this.showGroupBadge = true});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImage(context),
              _buildInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── 이미지 영역 ──────────────────────────────────────────
  Widget _buildImage(BuildContext context) {
    final discount = product.originalPrice != null && product.originalPrice! > product.price
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;

    // 배지 색상 결정
    Color badgeBg;
    String badgeText;
    if (product.isGroupOnly) {
      badgeBg = const Color(0xFF333333);
      badgeText = 'GROUP';
    } else if (product.isNewActive) {
      badgeBg = const Color(0xFF111111);
      badgeText = 'NEW';
    } else if (product.isSale && discount > 0) {
      badgeBg = const Color(0xFF333333);
      badgeText = 'SALE';
    } else {
      badgeBg = Colors.transparent;
      badgeText = '';
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 상품 이미지 (비율 자동 감지 → fit 자동 결정) ──
            Positioned.fill(
              child: product.images.isNotEmpty
                  ? _SmartProductImage(url: product.images.first)
                  : _placeholder(),
            ),

            // ── 좌상단 배지 (GROUP / NEW / SALE) ──
            if (badgeText.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // ── 우상단 할인율 ──
            if (discount > 0 && !product.isGroupOnly)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

            // ── 단체주문: GROUP일 때 할인율도 표시 ──
            if (discount > 0 && product.isGroupOnly)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

            // ── 무료배송 (우하단) ──
            if (product.isFreeShipping)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(6)),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // ── 품절 오버레이 (stockCount == 0) ──
            if (product.stockCount <= 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.image_not_supported_rounded, color: Color(0xFF444444), size: 28),
    );
  }

  // ── 상품 정보 영역 ──────────────────────────────────────
  Widget _buildInfo(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    final loc  = context.watch<LanguageProvider>().loc;

    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;
    final discount = hasDiscount
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 단체주문 전용 / 기성품 뱃지 (showGroupBadge=false 이면 숨김) ──
          if ((product.isGroupOnly || product.isReadyMade) && showGroupBadge) ...[
            Row(children: [
              if (product.isGroupOnly)
                Container(
                  margin: const EdgeInsets.only(right: 4, bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF888888),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '단체주문 전용',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              if (product.isReadyMade)
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '기성품',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ]),
          ],

          // ── 상품명 (2줄 고정 높이로 카드 크기 균일화) ──
          SizedBox(
            height: 11 * 1.3 * 2, // fontSize(11) × lineHeight(1.3) × 2줄
            child: Text(
              product.localizedName(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 3),

          // ── 가격 ──
          if (hasDiscount) ...[
            // 정가 (취소선)
            Text(
              '${_fmt(product.originalPrice!)}${loc.productWonUnit}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.35),
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _fmt(product.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  loc.productWonUnit,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '$discount%',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF111111),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 정가만
            Text(
              '${_fmt(product.price)}${loc.productWonUnit}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],

          // ── 별점 ──
          if (product.rating > 0 && product.reviewCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFFB300)),
                const SizedBox(width: 2),
                Text(
                  '${product.rating} (${product.reviewCount})',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ─────────────────────────────────────────────────────────────
/// 이미지 비율을 실시간 감지해 BoxFit을 자동 결정하는 위젯
///
/// 카드 비율 = 4:5 = 0.8
/// • 이미지 비율이 카드 비율과 ±30% 이내  → BoxFit.cover  (꽉 채움)
/// • 이미지가 카드보다 훨씬 가로형(>1.1)   → BoxFit.cover  (가로 꽉 채움)
/// • 이미지가 카드보다 훨씬 세로형(<0.55)  → BoxFit.contain (여백 유지)
///
/// 로딩 중에는 shimmer placeholder, 감지 완료 후 애니메이션 전환
// ─────────────────────────────────────────────────────────────
class _SmartProductImage extends StatefulWidget {
  final String url;
  const _SmartProductImage({required this.url});

  @override
  State<_SmartProductImage> createState() => _SmartProductImageState();
}

class _SmartProductImageState extends State<_SmartProductImage> {
  // 카드 비율 (4:5)
  static const double _cardRatio = 4 / 5;

  BoxFit _fit = BoxFit.cover; // 항상 cover
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _detectFit(widget.url);
  }

  @override
  void didUpdateWidget(_SmartProductImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() { _resolved = false; _fit = BoxFit.cover; });
      _detectFit(widget.url);
    }
  }

  /// 이미지를 한 번만 로드해 실제 픽셀 크기를 읽고 fit을 결정
  void _detectFit(String url) {
    if (url.isEmpty) return;

    ImageProvider provider;
    if (kIsWeb) {
      // 웹: ResizeImage 없이 원본 비율 그대로 읽음
      provider = NetworkImage(url);
    } else {
      provider = NetworkImage(url);
    }

    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w <= 0 || h <= 0) return;

        final imgRatio = w / h;
        BoxFit decided;

        // 모든 비율 → cover (카드에 꽉 채움)
        decided = BoxFit.cover;

        setState(() {
          _fit = decided;
          _resolved = true;
        });
      },
      onError: (_, __) {
        if (mounted) setState(() => _resolved = true);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: NetImage(
          widget.url,
          key: ValueKey('${widget.url}_$_fit'),
          fit: _fit,
          // width/height 미전달 → 부모(StackFit.expand + SizedBox.expand)가 크기 결정
          // double.infinity를 넘기면 ResizeImage가 1200×1200 강제 리사이즈 → 비율 왜곡
        ),
      ),
    );
  }
}
