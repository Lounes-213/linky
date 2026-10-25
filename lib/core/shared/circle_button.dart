import 'package:flutter/material.dart';
import 'shadows.dart';

class CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;

  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.iconSize = 22,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242740) : Colors.white;
    final ic = iconColor ?? (isDark ? const Color(0xFFF0F1F5) : const Color(0xFF1A1D26));

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: ClayShadows.circle(context),
        ),
        child: Icon(icon, color: ic, size: iconSize),
      ),
    );
  }
}
