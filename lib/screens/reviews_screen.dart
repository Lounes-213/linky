import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/shared_ui.dart';
import '../core/api/api_service.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;

  const ReviewsScreen({super.key, required this.productId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _reviews = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ApiService();
    final res = await api.get('${AppConstants.productsBase}/${widget.productId}/reviews');

    if (res.isSuccess && res.data != null) {
      setState(() {
        _summary = res.data!['summary'] ?? res.data!['stats'];
        final List<dynamic> items = res.data!['reviews'] ?? res.data!['data'] ?? [];
        _reviews = items.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error ?? 'Erreur lors du chargement';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: clayScaffoldBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: clayPrimary(context)))
                  : _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadReviews,
                          color: clayPrimary(context),
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            children: [
                              _buildSummarySection(),
                              const SizedBox(height: 20),
                              _buildReviewsList(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReviewSheet,
        backgroundColor: clayPrimary(context),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final loc = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Neumorphism.circle(
            context: context,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: onSurface),
              ),
            ),
          ),
          const Spacer(),
          Text(
            loc.reviews,
            style: TextStyle(
              color: onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final double avg = (_summary?['avg_rating'] ?? 0).toDouble();
    final int total = (_summary?['total_reviews'] ?? 0);

    return Neumorphism.light(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < avg.round() ? Icons.star : Icons.star_border,
                    color: LinkyColors.star,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$total avis',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = _summary?['${star}_star'] ?? 0;
                final percent = total > 0 ? (count / total) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.star, color: LinkyColors.star, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(LinkyColors.star),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    final loc = AppLocalizations.of(context);
    if (_reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Neumorphism.light(
                borderRadius: 24,
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(Icons.rate_review_outlined, size: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.noReviewsYet,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.writeReview,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.reviews,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews.map((r) => _buildReviewCard(r)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final int rating = (review['rating'] ?? 5).toInt();
    final String name = review['user_name'] ?? review['author'] ?? 'Utilisateur';
    final String? avatar = review['user_avatar'] ?? review['avatar'];
    final String title = review['title'] ?? '';
    final String comment = review['comment'] ?? review['text'] ?? '';
    final String date = _formatDate(review['created_at'] ?? review['date']);
    final List<dynamic> images = review['images'] ?? [];

    return Neumorphism.light(
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: LinkyColors.primaryLight,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: LinkyColors.star,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (ctx, i) => Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(images[i].toString()),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddReviewSheet() {
    int selectedRating = 5;
    final titleController = TextEditingController();
    final commentController = TextEditingController();
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: ListView(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.writeReview,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedRating ? Icons.star : Icons.star_border,
                        color: LinkyColors.star,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Neumorphism.light(
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                context: context,
                child: TextField(
                  controller: titleController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: loc.title,
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Neumorphism.light(
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                context: context,
                child: TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: loc.comment,
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  if (commentController.text.isEmpty) return;
                  final api = ApiService();
                  await api.post(
                    '${AppConstants.productsBase}/${widget.productId}/reviews',
                    body: {
                      'rating': selectedRating,
                      'title': titleController.text,
                      'comment': commentController.text,
                    },
                  );
                  Navigator.pop(ctx);
                  _loadReviews();
                },
                child: Neumorphism.button(
                  borderRadius: 16,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      loc.submitReview,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildErrorState() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: LinkyColors.discount),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadReviews,
            child: Neumorphism.button(
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(loc.retry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
