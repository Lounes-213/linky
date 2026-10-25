import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class LinkyStatsGrid extends StatelessWidget {
  final String views;
  final String score;
  final String refs;
  final String rank;

  const LinkyStatsGrid({
    super.key,
    required this.views,
    required this.score,
    required this.refs,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context, 'Views', views, LinkyColors.neonGreen),
        _buildStatCard(context, 'Score', score, LinkyColors.neonPurple),
        _buildStatCard(context, 'Refs', refs, LinkyColors.neonAmber),
        _buildStatCard(context, 'Rank', rank, LinkyColors.neonCrimson),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color accentColor) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
