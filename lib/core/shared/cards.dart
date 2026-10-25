import 'package:flutter/material.dart';
import 'shadows.dart';

class ClayCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;

  const ClayCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? const Color(0xFF242740) : Colors.white);

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ClayShadows.card(context),
      ),
      child: child,
    );
  }
}

class ClayIconCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final double size;

  const ClayIconCard({
    super.key,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.size = 82,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242740) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ClayShadows.iconCard(context),
        ),
        child: Icon(icon, color: iconColor, size: size * 0.35),
      ),
    );
  }
}

class ClayStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ClayStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1A1D26);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6B6F90)
        : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF242740)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ClayShadows.iconCard(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: txt)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
