import 'package:flutter/material.dart';
import 'neumorphic_ui.dart';
import '../theme.dart';

/// A single review/comment displayed in neumorphic style.
class NeuReviewCard extends StatelessWidget {
  final String authorName;
  final String? authorAvatar;
  final double rating;
  final String comment;
  final String? date;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final bool isLiked;
  final int? likeCount;

  const NeuReviewCard({
    super.key,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.comment,
    this.date,
    this.onLike,
    this.onReply,
    this.isLiked = false,
    this.likeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeumorphicContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      depth: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? LinkyColors.neuDarkIconBg : LinkyColors.neuLightIconBg,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? LinkyColors.neuDarkShadowDark : LinkyColors.neuLightShadowDark,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: isDark ? LinkyColors.neuDarkShadowLight : Colors.white,
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: authorAvatar != null && authorAvatar!.isNotEmpty
                      ? Image.network(authorAvatar!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar())
                      : _defaultAvatar(),
                ),
              ),
              const SizedBox(width: 12),

              // Name + Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? LinkyColors.neuDarkText : LinkyColors.neuLightText,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        date!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Rating stars
              if (rating > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: i < rating ? LinkyColors.star : (isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted).withValues(alpha: 0.3),
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment text
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? LinkyColors.neuDarkText : LinkyColors.neuLightText,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons: Like + Reply
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 18,
                      color: isLiked ? LinkyColors.neonCrimson : (isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted),
                    ),
                    if (likeCount != null && likeCount! > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onReply != null) ...[
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: onReply,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply_outlined,
                        size: 18,
                        color: isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Répondre',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: LinkyColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
          style: TextStyle(
            color: LinkyColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// A full reviews section with header, summary stats, and list.
class NeuReviewsSection extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final List<Map<String, dynamic>> reviews;
  final VoidCallback? onAddReview;

  const NeuReviewsSection({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
    this.onAddReview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avis & Commentaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? LinkyColors.neuDarkText : LinkyColors.neuLightText,
              ),
            ),
            if (onAddReview != null)
              NeumorphicButton(
                onTap: onAddReview!,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_comment_outlined, size: 16, color: LinkyColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Ajouter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: LinkyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary card
        NeumorphicContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          depth: 3,
          child: Row(
            children: [
              // Average rating circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? LinkyColors.neuDarkIconBg : LinkyColors.neuLightIconBg,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? LinkyColors.neuDarkShadowDark : LinkyColors.neuLightShadowDark,
                      offset: const Offset(3, 3),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: isDark ? LinkyColors.neuDarkShadowLight : Colors.white,
                      offset: const Offset(-3, -3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: LinkyColors.primary,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: i < averageRating.round() ? LinkyColors.star : Colors.grey.shade300,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Review bars
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = reviews.where((r) => (r['rating'] ?? 0).round() == star).length;
                    final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            child: Text(
                              '$star',
                              style: TextStyle(fontSize: 11, color: LinkyColors.star, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark ? LinkyColors.neuDarkIconBg : LinkyColors.neuLightIconBg,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? LinkyColors.neuDarkShadowDark : LinkyColors.neuLightShadowDark,
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: LinkyColors.star,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: TextStyle(fontSize: 11, color: isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted),
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
        ),
        const SizedBox(height: 16),

        // Reviews list
        if (reviews.isEmpty)
          NeumorphicContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: 18,
            depth: 2,
            isInnerShadow: true,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 40, color: (isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted).withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun avis pour le moment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? LinkyColors.neuDarkText : LinkyColors.neuLightText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Soyez le premier à donner votre avis !',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? LinkyColors.neuDarkTextMuted : LinkyColors.neuLightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...reviews.map((r) => NeuReviewCard(
                authorName: r['author_name']?.toString() ?? 'Anonyme',
                authorAvatar: r['author_avatar']?.toString(),
                rating: (r['rating'] ?? 0).toDouble(),
                comment: r['comment']?.toString() ?? '',
                date: r['created_at']?.toString(),
                isLiked: r['is_liked'] == true,
                likeCount: r['like_count'],
              )),
      ],
    );
  }
}

/// Modal for adding a new review with neumorphic styling.
Future<Map<String, dynamic>?> showNeuReviewModal(BuildContext context) {
  final ratingCtrl = ValueNotifier<double>(5.0);
  final commentCtrl = TextEditingController();

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
        decoration: BoxDecoration(
          color: NeuColors.bg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: NeuColors.shadowLight(context), offset: const Offset(0, -6), blurRadius: 12),
            BoxShadow(color: NeuColors.shadowDark(context).withValues(alpha: 0.2), offset: const Offset(0, -2), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44, height: 5,
                decoration: BoxDecoration(
                  color: NeuColors.textMuted(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                NeumorphicContainer(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 14,
                  depth: 4,
                  child: Icon(Icons.rate_review_outlined, color: LinkyColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  'Donner votre avis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NeuColors.text(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rating selector
            Center(
              child: ValueListenableBuilder<double>(
                valueListenable: ratingCtrl,
                builder: (context, rating, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => ratingCtrl.value = (i + 1).toDouble(),
                        onLongPressStart: (_) => null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(begin: i < rating ? 1.0 : 0.0, end: i < rating ? 1.0 : 0.0),
                            builder: (context, value, child) {
                              return Icon(
                                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 42,
                                color: i < rating ? LinkyColors.star : NeuColors.textMuted(context).withValues(alpha: 0.3),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Comment field
            NeumorphicContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 16,
              depth: 2,
              isInnerShadow: true,
              child: TextField(
                controller: commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience...',
                  hintStyle: TextStyle(color: NeuColors.textMuted(context).withValues(alpha: 0.5)),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: NeuColors.text(context)),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: NeumorphicButton(
                onTap: () {
                  Navigator.pop(ctx, {
                    'rating': ratingCtrl.value.round(),
                    'comment': commentCtrl.text.trim(),
                  });
                },
                borderRadius: 16,
                padding: EdgeInsets.zero,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B7FFF), Color(0xFF5267FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Publier',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NeuColors.shadowLight(context),
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
