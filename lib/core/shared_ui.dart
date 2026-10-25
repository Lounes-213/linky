library shared_ui;

export 'shared/shadows.dart';
export 'shared/colors.dart';
export 'shared/appbar.dart';
export 'shared/circle_button.dart';
export 'shared/search_bar.dart';
export 'shared/cards.dart';
export 'shared/buttons.dart';
export 'shared/chips.dart';
export 'shared/section_title.dart';
export 'shared/text_field.dart';
export 'shared/bottom_navigation.dart';
export 'shared/typography.dart';

import 'package:flutter/material.dart';
import 'shared/colors.dart';
import 'shared/cards.dart';
import 'shared/section_title.dart';
import 'shared/search_bar.dart';
import 'shared/circle_button.dart';
import 'shared/chips.dart';

const Color linkyPrimary = Color(0xFF6C63FF);
const Color linkyBorder = Color(0xFFE5E7EB);
const Color linkyTextPrimary = Color(0xFF1A1D26);
const Color linkyTextSecondary = Color(0xFF6B7280);
const Color linkyError = Color(0xFFFF6B6B);
const Color linkySuccess = Color(0xFF6BCB77);

// ─── BACKWARD-COMPAT ALIASES ──────────────────────────────
class LinkyColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color accent = Color(0xFF38BDF8);
  static const Color accentDark = Color(0xFF0EA5E9);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FC);
  static const Color background = Color(0xFFF6F7FB);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF1F5F9);

  static const Color discount = Color(0xFFFF6B6B);
  static const Color star = Color(0xFFFFD93D);
  static const Color neonGreen = Color(0xFF6BCB77);
  static const Color neonPurple = primary;
  static const Color neonAmber = star;
  static const Color neonCrimson = discount;

  static const Color darkBackground = Color(0xFF1A1D2E);
  static const Color darkSurface = Color(0xFF242740);
  static const Color darkTextPrimary = Color(0xFFF0F1F5);
  static const Color darkTextSecondary = Color(0xFF9CA3C0);

  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  static const Color neuLightBg = Color(0xFFF6F7FB);
  static const Color neuLightShadowLight = Colors.white;
  static const Color neuLightShadowDark = Color(0xFFD9E0EF);
  static const Color neuLightText = Color(0xFF1A1D26);
  static const Color neuLightTextMuted = Color(0xFF6B7280);
  static const Color neuLightIconBg = Color(0xFFE5E7EB);

  static const Color neuDarkBg = Color(0xFF242740);
  static const Color neuDarkShadowLight = Color(0xFF3A3660);
  static const Color neuDarkShadowDark = Color(0xFF12102A);
  static const Color neuDarkText = Color(0xFFF0F1F5);
  static const Color neuDarkTextMuted = Color(0xFF6B6F90);
  static const Color neuDarkIconBg = Color(0xFF363955);
}

class SharedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SharedCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return ClayCard(child: child, padding: padding, margin: margin);
  }
}

class SharedSectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const SharedSectionTitle({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return ClaySectionTitle(title: title, action: action);
  }
}

class SharedSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  const SharedSearchBar({super.key, required this.hint, this.onChanged, this.controller, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return ClaySearchBar(hint: hint, onChanged: onChanged, controller: controller, suffixIcon: suffixIcon);
  }
}

class SharedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  final double? iconSize;

  const SharedIconButton({super.key, required this.icon, required this.onTap, this.color, this.size = 42, this.iconSize});

  @override
  Widget build(BuildContext context) {
    return CircleButton(
      icon: icon,
      onTap: onTap,
      size: size,
      iconSize: iconSize ?? (size * 0.45),
      iconColor: color,
    );
  }
}

class SharedChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final String? style;

  const SharedChip({super.key, required this.label, this.isSelected = false, this.onTap, this.color, this.style});

  @override
  Widget build(BuildContext context) {
    return ClayChip(label: label, isSelected: isSelected, onTap: onTap, color: color);
  }
}

class SharedStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const SharedStatCard({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClayStatCard(icon: icon, label: label, value: value, color: color);
  }
}

class NeuColors {
  static Color bg(BuildContext context) => clayBg(context);
  static Color shadowLight(BuildContext context) => Colors.white;
  static Color shadowDark(BuildContext context) => clayBorder(context);
  static Color text(BuildContext context) => clayText(context);
  static Color textMuted(BuildContext context) => clayTextMuted(context);
  static Color iconBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF363955) : const Color(0xFFE5E7EB);
  }
}

class Neumorphism {
  static Widget light({required Widget child, double borderRadius = 28, Color? color, EdgeInsets? margin, EdgeInsets? padding, BuildContext? context, Border? border}) {
    return ClayCard(child: child, radius: borderRadius, color: color, margin: margin, padding: padding);
  }

  static Widget flat({required Widget child, double borderRadius = 20, Color? color, EdgeInsets? margin, EdgeInsets? padding, BuildContext? context}) {
    return ClayCard(child: child, radius: borderRadius, color: color, margin: margin, padding: padding);
  }

  static Widget circle({required Widget child, double size = 40, Color? color, BuildContext? context}) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? const Color(0xFF242740) : Colors.white);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: const [],
      ),
      child: child,
    );
  }

  static Widget inset({required Widget child, double borderRadius = 18, Color? color, EdgeInsets? margin, EdgeInsets? padding, BuildContext? context}) {
    return ClayCard(child: child, radius: borderRadius, color: color, margin: margin, padding: padding);
  }

  static Widget button({required Widget child, double borderRadius = 20, Color color = const Color(0xFF6C63FF)}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  static Widget heavy({required Widget child, double borderRadius = 28, Color? color, EdgeInsets? margin, EdgeInsets? padding, BuildContext? context}) {
    return ClayCard(child: child, radius: borderRadius, color: color, margin: margin, padding: padding);
  }
}
