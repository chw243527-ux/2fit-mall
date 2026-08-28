import '../../utils/theme.dart';
// admin_review_tab.dart — 리뷰 관리 탭
import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../services/review_service.dart';

class AdminReviewTab extends StatefulWidget {
  const AdminReviewTab({super.key});

  @override
  State<AdminReviewTab> createState() => _AdminReviewTabState();
}

class _AdminReviewTabState extends State<AdminReviewTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  double? _filterRating; // null = 전체
  bool _loading = false;
  List<ReviewModel> _reviews = [];
  List<ReviewModel> _filtered = [];

  // 상품명 캐시 (productId → name)
  final Map<String, String> _productNames = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final reviews = await ReviewService.getAllReviews();
      // 상품명 일괄 조회
      final ids = reviews.map((r) => r.productId).toSet();
      for (final id in ids) {
        if (id.isNotEmpty && !_productNames.containsKey(id)) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('products')
                .doc(id)
                .get();
            if (doc.exists) {
              _productNames[id] = (doc.data()?['name'] as String?) ?? id;
            }
          } catch (_) {}
        }
      }
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _applyFilter();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = List<ReviewModel>.from(_reviews);
    if (_filterRating != null) {
      list = list.where((r) => r.rating == _filterRating).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (r) =>
                r.userName.toLowerCase().contains(q) ||
                r.content.toLowerCase().contains(q) ||
                (_productNames[r.productId] ?? '').toLowerCase().contains(q) ||
                r.productId.toLowerCase().contains(q),
          )
          .toList();
    }
    setState(() => _filtered = list);
  }

  Future<void> _toggleBestReview(ReviewModel review) async {
    final saved = await ReviewService.setBestReview(
      reviewId: review.id,
      productId: review.productId,
      isBest: !review.isBest,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved
          ? (review.isBest ? '베스트 리뷰를 해제했습니다.' : '베스트 리뷰로 선정했습니다.')
          : '베스트 상태 저장에 실패했습니다.')),
    );
    if (saved) await _loadReviews();
  }

  Future<void> _showAdminReplyDialog(ReviewModel review) async {
    final controller = TextEditingController(text: review.adminReply);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(review.adminReply.isEmpty ? '리뷰 답변 작성' : '리뷰 답변 수정'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: '고객에게 보여질 답변',
              hintText: '리뷰에 대한 감사와 안내를 입력하세요.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          if (review.adminReply.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('답변 삭제'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ReviewService.saveAdminReply(
                reviewId: review.id,
                reply: controller.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext, ok);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 답변이 저장되었습니다.')),
      );
      await _loadReviews();
    }
  }

  void _showReviewDetail(ReviewModel r) {
    final productName = _productNames[r.productId] ?? r.productId;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _StarRow(r.rating),
            const SizedBox(width: 8),
            Expanded(
              child: Text(r.userName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(context.loc.t('상품', '상품'), productName),
                _DetailRow(context.loc.t('사이즈', '사이즈'),
                    r.size.isNotEmpty ? r.size : '-'),
                _DetailRow(context.loc.t('색상', '색상'),
                    r.color.isNotEmpty ? r.color : '-'),
                _DetailRow(context.loc.t('작성일', '작성일'), _fmtDate(r.createdAt)),
                const SizedBox(height: 10),
                Text(context.loc.t('내용', '내용'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(r.content,
                      style: const TextStyle(fontSize: 14, height: 1.5)),
                ),
                if (r.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(context.loc.t('첨부 이미지', '첨부 이미지'),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: r.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(r.images[i],
                            width: 80, height: 80, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _toggleBestReview(r);
            },
            icon: Icon(r.isBest
                ? Icons.emoji_events_rounded
                : Icons.emoji_events_outlined),
            label: Text(r.isBest ? '베스트 해제' : '베스트 선정'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAdminReplyDialog(r);
            },
            icon: const Icon(Icons.reply_outlined),
            label: Text(r.adminReply.isEmpty ? '답변 작성' : '답변 수정'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.loc.t('닫기', '닫기'))),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final avgRating = _reviews.isEmpty
        ? 0.0
        : _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
    final starDist = <double, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final key = r.rating.clamp(1, 5).toDouble().floorToDouble();
      starDist[key] = (starDist[key] ?? 0) + 1;
    }

    return Column(
      children: [
        // ── 관리 헤더 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text('리뷰 관리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const Text('원문 보호 · 베스트 선정 · 답변 관리',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // ── 상단 통계 카드 ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 평균 평점
              Container(
                width: 130,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  children: [
                    Text(avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.warning)),
                    _StarRow(avgRating),
                    const SizedBox(height: 4),
                    Text(context.loc.t('총 _개 리뷰', '총 ${_reviews.length}개 리뷰'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 별점 분포
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final cnt = starDist[star.toDouble()] ?? 0;
                    final pct = _reviews.isEmpty ? 0.0 : cnt / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star★',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.warning),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                              width: 28,
                              child: Text('$cnt',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── 검색/필터 바 ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: context.loc.t('작성자 상품명 내용 검색', '작성자, 상품명, 내용 검색'),
                          hintStyle: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.search,
                              size: 16, color: AppColors.textHint),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                    _applyFilter();
                                  })
                              : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          setState(() => _searchQuery = v);
                          _applyFilter();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: context.loc.t('새로고침', '새로고침'),
                    onPressed: _loadReviews,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                        label: '전체',
                        selected: _filterRating == null,
                        onTap: () {
                          setState(() => _filterRating = null);
                          _applyFilter();
                        }),
                    const SizedBox(width: 4),
                    ...[5, 4, 3, 2, 1].map((s) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _FilterChip(
                            label: '$s★',
                            selected: _filterRating == s.toDouble(),
                            color: AppColors.warning,
                            onTap: () {
                              setState(() => _filterRating = s.toDouble());
                              _applyFilter();
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── 리뷰 목록 ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(context.loc.t('리뷰가 없습니다', '리뷰가 없습니다'),
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReviewCard(
                        review: _filtered[i],
                        productName: _productNames[_filtered[i].productId] ??
                            _filtered[i].productId,
                        onBest: () => _toggleBestReview(_filtered[i]),
                        onReply: () => _showAdminReplyDialog(_filtered[i]),
                        onTap: () => _showReviewDetail(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── 리뷰 카드 ──────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String productName;
  final VoidCallback onBest;
  final VoidCallback onReply;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.review,
    required this.productName,
    required this.onBest,
    required this.onReply,
    required this.onTap,
  });

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: AppColors.surfaceGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StarRow(review.rating),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(productName,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                if (review.isBest)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.emoji_events_rounded,
                        size: 17, color: AppColors.warning),
                  ),
                Text(_fmtDate(review.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(review.isBest
                      ? Icons.emoji_events_rounded
                      : Icons.emoji_events_outlined,
                      size: 18,
                      color: review.isBest
                          ? AppColors.warning
                          : AppColors.textSecondary),
                  tooltip: review.isBest ? '베스트 해제' : '베스트 선정',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onBest,
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: Icon(review.adminReply.isEmpty
                      ? Icons.reply_outlined
                      : Icons.reply_rounded,
                      size: 18,
                      color: review.adminReply.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.info),
                  tooltip: review.adminReply.isEmpty ? '답변 작성' : '답변 수정',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onReply,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(review.userName,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
                if (review.size.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(context.loc.t('사이즈 _', '사이즈: ${review.size}'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.info)),
                  ),
                ],
                if (review.color.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(context.loc.t('색상 _', '색상: ${review.color}'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.accent)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(review.content,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            if (review.adminReply.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('관리자 답변',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(review.adminReply,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(review.images[i],
                        width: 60, height: 60, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 별점 위젯 ──────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow(this.rating);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded,
              size: 14, color: AppColors.warning);
        } else if (i < rating) {
          return const Icon(Icons.star_half_rounded,
              size: 14, color: AppColors.warning);
        }
        return const Icon(Icons.star_border_rounded,
            size: 14, color: AppColors.border);
      }),
    );
  }
}

// ── 필터 칩 ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.info;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? c : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c : AppColors.textSecondary,
            )),
      ),
    );
  }
}

// ── 상세 정보 행 ──────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 48,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
