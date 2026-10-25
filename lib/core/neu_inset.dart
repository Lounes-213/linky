import 'package:flutter/material.dart';

class NeuInsetShadow extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color bgColor;
  final Color lightColor;
  final Color darkColor;
  final Offset offset;
  final double blurRadius;

  const NeuInsetShadow({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.bgColor = const Color(0xFFEEF2F8),
    this.lightColor = Colors.white,
    this.darkColor = const Color(0xFFCDD5E0),
    this.offset = const Offset(4, 4),
    this.blurRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InsetShadowPainter(
        borderRadius: borderRadius,
        bgColor: bgColor,
        lightColor: lightColor,
        darkColor: darkColor,
        offset: offset,
        blurRadius: blurRadius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          color: bgColor,
          child: child,
        ),
      ),
    );
  }
}

class _InsetShadowPainter extends CustomPainter {
  final double borderRadius;
  final Color bgColor;
  final Color lightColor;
  final Color darkColor;
  final Offset offset;
  final double blurRadius;

  _InsetShadowPainter({
    required this.borderRadius,
    required this.bgColor,
    required this.lightColor,
    required this.darkColor,
    required this.offset,
    required this.blurRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    final blur = blurRadius;

    final darkPaint = Paint()
      ..color = darkColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    canvas.drawRect(Rect.fromLTRB(size.width * 0.3, -blur, size.width + blur, size.height + blur), darkPaint);
    canvas.drawRect(Rect.fromLTRB(-blur, size.height * 0.3, size.width + blur, size.height + blur), darkPaint);

    final lightPaint = Paint()
      ..color = lightColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    canvas.drawRect(Rect.fromLTRB(-blur, -blur, size.width * 0.7, size.height + blur), lightPaint);
    canvas.drawRect(Rect.fromLTRB(-blur, -blur, size.width + blur, size.height * 0.7), lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InsetShadowPainter oldDelegate) =>
      oldDelegate.bgColor != bgColor ||
      oldDelegate.lightColor != lightColor ||
      oldDelegate.darkColor != darkColor;
}

class Neumorphism {
  static Widget light({
    required Widget child,
    double borderRadius = 28,
    Color? color,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BuildContext? context,
    Border? border,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? const Color(0xFF252836) : const Color(0xFFEEF2F8));
    final sLight = isDark ? const Color(0xFF2D3044) : Colors.white;
    final sDark = isDark ? const Color(0xFF1A1D2A) : const Color(0xFFD5DDE8);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(color: sLight, offset: const Offset(-10, -10), blurRadius: 20),
          BoxShadow(color: sDark, offset: const Offset(10, 10), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }

  static Widget flat({
    required Widget child,
    double borderRadius = 20,
    Color? color,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BuildContext? context,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? const Color(0xFF252836) : const Color(0xFFEEF2F8));
    final borderColor = isDark ? const Color(0xFF2D3044).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  static Widget circle({
    required Widget child,
    double size = 40,
    Color? color,
    BuildContext? context,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? const Color(0xFF252836) : const Color(0xFFEEF2F8));
    final sLight = isDark ? const Color(0xFF2D3044) : Colors.white;
    final sDark = isDark ? const Color(0xFF1A1D2A) : const Color(0xFFD5DDE8);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: sLight, offset: const Offset(-10, -10), blurRadius: 20),
          BoxShadow(color: sDark, offset: const Offset(10, 10), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }

  static Widget inset({
    required Widget child,
    double borderRadius = 18,
    Color? color,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BuildContext? context,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? const Color(0xFF252836) : const Color(0xFFEEF2F8));
    final sLight = isDark ? const Color(0xFF2D3044) : Colors.white;
    final sDark = isDark ? const Color(0xFF1A1D2A) : const Color(0xFFCDD5E0);

    return Container(
      margin: margin,
      padding: padding,
      child: NeuInsetShadow(
        borderRadius: borderRadius,
        bgColor: bgColor,
        lightColor: sLight,
        darkColor: sDark,
        child: child,
      ),
    );
  }

  static Widget button({
    required Widget child,
    double borderRadius = 16,
    Color color = const Color(0xFF0EA5E9),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget heavy({
    required Widget child,
    double borderRadius = 28,
    Color? color,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BuildContext? context,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? const Color(0xFF252836) : const Color(0xFFEEF2F8));
    final sLight = isDark ? const Color(0xFF2D3044) : Colors.white;
    final sDark = isDark ? const Color(0xFF15171F) : const Color(0xFFAEAECE);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: sLight, offset: const Offset(-10, -10), blurRadius: 30),
          BoxShadow(color: sDark, offset: const Offset(10, 10), blurRadius: 30),
        ],
      ),
      child: child,
    );
  }
}
