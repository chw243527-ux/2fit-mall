import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/app_drawer.dart';
import 'category_detail_screen.dart';
import '../not_found_screen.dart';

/// URL 직접 접근용 래퍼 (/category/:name)
/// 카테고리명으로 CategoryData를 찾아 CategoryDetailScreen을 렌더링한다.
class CategoryByNameScreen extends StatelessWidget {
  final String categoryName; // URL 인코딩 전 한글 카테고리명
  const CategoryByNameScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final loc = context.read<LanguageProvider>().loc;
    final categories = getCategories(loc);

    // URL에서 온 categoryName과 비교 (대소문자·공백 무시)
    final normalized = categoryName.trim().toLowerCase();
    CategoryData? matched;
    for (final cat in categories) {
      if (cat.name.trim().toLowerCase() == normalized ||
          cat.name.replaceAll(' ', '').toLowerCase() ==
              normalized.replaceAll(' ', '')) {
        matched = cat;
        break;
      }
    }

    if (matched == null) {
      return const NotFoundScreen();
    }

    return CategoryDetailScreen(
      categoryName: matched.name,
      categoryColor: matched.color,
      categoryIcon: matched.icon,
      subCategories: matched.subCategories,
    );
  }
}
