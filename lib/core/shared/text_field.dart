import 'package:flutter/material.dart';
import 'shadows.dart';

class ClayTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;

  const ClayTextField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242740) : Colors.white;
    final txtColor = isDark ? const Color(0xFFF0F1F5) : const Color(0xFF1A1D26);
    final hintColor = isDark ? const Color(0xFF6B6F90) : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ClayShadows.card(context),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: txtColor, fontFamily: 'Outfit', fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontFamily: 'Outfit'),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
    );
  }
}
