import 'package:flutter/material.dart';

class ClayColors {
  // ─── LIGHT ─────────────────────────────
  static const Color lightBg = Color(0xFFF6F7FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1D26);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // ─── DARK ─────────────────────────────
  static const Color darkBg = Color(0xFF1A1D2E);
  static const Color darkCard = Color(0xFF242740);
  static const Color darkText = Color(0xFFF0F1F5);
  static const Color darkTextSecondary = Color(0xFF9CA3C0);
  static const Color darkTextMuted = Color(0xFF6B6F90);
  static const Color darkBorder = Color(0xFF363955);

  // ─── SHARED ─────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color discount = Color(0xFFFF6B6B);
  static const Color star = Color(0xFFFFD93D);
  static const Color success = Color(0xFF6BCB77);
}

Color clayBg(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.darkBg : ClayColors.lightBg;
Color clayCard(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.darkCard : ClayColors.lightCard;
Color clayText(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.darkText : ClayColors.lightText;
Color clayTextSecondary(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.darkTextSecondary : ClayColors.lightTextSecondary;
Color clayTextMuted(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.darkTextMuted : ClayColors.lightTextMuted;
Color clayBorder(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.darkBorder : ClayColors.lightBorder;
Color clayPrimary(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark ? ClayColors.primaryLight : ClayColors.primary;
Color clayScaffoldBg(BuildContext ctx) => clayBg(ctx);
