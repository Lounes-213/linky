import 'package:flutter/material.dart';

class ClayShadows {
  // ─── LIGHT MODE ─────────────────────────────
  static const Color _lightShadowLight = Colors.white;
  static const Color _lightShadowDark = Color(0xFFD9E0EF);

  // ─── DARK MODE ─────────────────────────────
  static const Color _darkShadowLight = Color(0xFF3A3660);
  static const Color _darkShadowDark = Color(0xFF12102A);

  // ─── CARD SHADOWS (radius 28, blur 18, offset 8) ─────────────────────────────
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? _darkShadowLight : _lightShadowLight,
        blurRadius: 18,
        offset: const Offset(-8, -8),
      ),
      BoxShadow(
        color: isDark ? _darkShadowDark : _lightShadowDark,
        blurRadius: 18,
        offset: const Offset(8, 8),
      ),
    ];
  }

  // ─── CIRCLE SHADOWS (blur 12, offset 5) ─────────────────────────────
  static List<BoxShadow> circle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? _darkShadowLight : _lightShadowLight,
        blurRadius: 12,
        offset: const Offset(-5, -5),
      ),
      BoxShadow(
        color: isDark ? _darkShadowDark : _lightShadowDark,
        blurRadius: 12,
        offset: const Offset(5, 5),
      ),
    ];
  }

  // ─── SEARCH BAR SHADOWS (blur 15, offset 6) ─────────────────────────────
  static List<BoxShadow> searchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? _darkShadowLight : _lightShadowLight,
        blurRadius: 15,
        offset: const Offset(-6, -6),
      ),
      BoxShadow(
        color: isDark ? _darkShadowDark : _lightShadowDark,
        blurRadius: 15,
        offset: const Offset(6, 6),
      ),
    ];
  }

  // ─── BOTTOM NAV SHADOWS (blur 20, offset 6) ─────────────────────────────
  static List<BoxShadow> bottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? _darkShadowLight : _lightShadowLight,
        blurRadius: 20,
        offset: const Offset(-6, -6),
      ),
      BoxShadow(
        color: isDark ? _darkShadowDark : _lightShadowDark,
        blurRadius: 20,
        offset: const Offset(6, 6),
      ),
    ];
  }

  // ─── ICON CARD SHADOWS (blur 14, offset 5) ─────────────────────────────
  static List<BoxShadow> iconCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? _darkShadowLight : _lightShadowLight,
        blurRadius: 14,
        offset: const Offset(-5, -5),
      ),
      BoxShadow(
        color: isDark ? _darkShadowDark : _lightShadowDark,
        blurRadius: 14,
        offset: const Offset(5, 5),
      ),
    ];
  }

  // ─── SMALL SHADOWS (blur 10, offset 4) ─────────────────────────────
  static List<BoxShadow> small(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? _darkShadowLight : _lightShadowLight,
        blurRadius: 10,
        offset: const Offset(-4, -4),
      ),
      BoxShadow(
        color: isDark ? _darkShadowDark : _lightShadowDark,
        blurRadius: 10,
        offset: const Offset(4, 4),
      ),
    ];
  }
}
