import 'package:flutter/material.dart';

class ClayPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool fullWidth;
  final IconData? icon;

  const ClayPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        minimumSize: fullWidth ? const Size(double.infinity, 58) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          fontFamily: 'Outfit',
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class ClaySecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool fullWidth;
  final IconData? icon;

  const ClaySecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF363955) : const Color(0xFFE5E7EB);
    final txtColor = isDark ? const Color(0xFFF0F1F5) : const Color(0xFF6C63FF);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: fullWidth ? const Size(double.infinity, 58) : null,
        side: BorderSide(color: borderColor, width: 1.5),
        foregroundColor: txtColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          fontFamily: 'Outfit',
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}
