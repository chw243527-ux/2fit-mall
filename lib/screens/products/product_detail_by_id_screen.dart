import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/product_service.dart';
import 'product_detail_screen.dart';
import '../not_found_screen.dart';

/// URL 직접 접근용 래퍼 (/products/:id)
/// Firestore에서 product를 조회한 뒤 ProductDetailScreen을 렌더링한다.
class ProductDetailByIdScreen extends StatefulWidget {
  final String productId;
  const ProductDetailByIdScreen({super.key, required this.productId});

  @override
  State<ProductDetailByIdScreen> createState() =>
      _ProductDetailByIdScreenState();
}

class _ProductDetailByIdScreenState extends State<ProductDetailByIdScreen> {
  ProductModel? _product;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ProductService.getProductById(widget.productId);
      if (!mounted) return;
      if (p == null) {
        setState(() {
          _loading = false;
          _notFound = true;
        });
      } else {
        setState(() {
          _loading = false;
          _product = p;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_notFound || _product == null) {
      return const NotFoundScreen();
    }
    return ProductDetailScreen(product: _product!);
  }
}
