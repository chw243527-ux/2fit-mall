import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../utils/theme.dart';
import '../../widgets/net_image.dart';

/// 팝업 공지와 같은 Firestore notices 컬렉션을 상시 열람하는 고객용 페이지입니다.
class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoticeProvider>().loadFromFirestore();
    });
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'event':
      case 'promo':
        return 'EVENT';
      case 'delivery':
        return 'DELIVERY';
      case 'warning':
        return 'IMPORTANT';
      case 'update':
        return 'UPDATE';
      default:
        return 'NOTICE';
    }
  }

  String _date(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>().language;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        title: const Text(
          'NOTICE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4),
        ),
      ),
      body: Consumer<NoticeProvider>(
        builder: (context, provider, _) {
          final notices = provider.activeNotices;
          if (provider.isLoading && notices.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.loadFromFirestore,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STAY\nIN THE LOOP.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 0.94,
                          letterSpacing: -1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '배송, 발매, 이벤트와 운영 안내를 확인하세요.',
                        style: TextStyle(color: Color(0xFFD2D0CA), fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (notices.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 54),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.campaign_outlined, color: AppColors.textHint, size: 32),
                        SizedBox(height: 14),
                        Text('등록된 공지사항이 없습니다.', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('새 소식은 이 페이지에서 언제든 확인할 수 있습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  ...notices.map((notice) {
                    final expanded = _expandedId == notice.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => setState(() {
                            _expandedId = expanded ? null : notice.id;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _themeLabel(notice.theme),
                                              style: const TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              notice.localizedTitle(language),
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 16,
                                                height: 1.35,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.25,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _date(notice.createdAt),
                                              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        expanded ? Icons.remove_rounded : Icons.add_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                if (expanded) ...[
                                  const Divider(height: 1, color: AppColors.border),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (notice.imageUrl.trim().isNotEmpty) ...[
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: NetImage(notice.imageUrl, fit: BoxFit.cover),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        Text(
                                          notice.localizedContent(language),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                            height: 1.75,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
