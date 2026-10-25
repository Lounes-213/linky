import 'package:flutter/material.dart';

class ClayTypography {
  static const String fontFamily = 'Outfit';

  static TextStyle h1(BuildContext context) => TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1A1D26),
  );

  static TextStyle h2(BuildContext context) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    letterSpacing: -0.3,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1A1D26),
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1A1D26),
  );

  static TextStyle bodySecondary(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3C0)
        : const Color(0xFF6B7280),
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6B6F90)
        : const Color(0xFF9CA3AF),
  );

  static TextStyle button() => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    color: Colors.white,
  );
}
