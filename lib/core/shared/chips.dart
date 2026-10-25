import 'package:flutter/material.dart';
import 'shadows.dart';

class ClayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;

  const ClayChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? const Color(0xFF6C63FF);
    final bg = isSelected ? c : (isDark ? const Color(0xFF242740) : Colors.white);
    final txtColor = isSelected ? Colors.white : (isDark ? const Color(0xFFF0F1F5) : const Color(0xFF1A1D26));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ClayShadows.small(context),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: txtColor,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}

class ClayFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const ClayFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = const Color(0xFF6C63FF);
    final bg = isSelected ? c.withValues(alpha: 0.15) : (isDark ? const Color(0xFF242740) : Colors.white);
    final txtColor = isSelected ? c : (isDark ? const Color(0xFF9CA3C0) : const Color(0xFF6B7280));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? c : (isDark ? const Color(0xFF363955) : const Color(0xFFE5E7EB)),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: txtColor,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}
