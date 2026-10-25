import 'package:flutter/material.dart';
import 'shadows.dart';

class ClaySearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  const ClaySearchBar({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
    this.suffixIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242740) : Colors.white;
    final hintColor = isDark ? const Color(0xFF6B6F90) : const Color(0xFF9CA3AF);
    final iconColor = isDark ? const Color(0xFF6B6F90) : const Color(0xFF9CA3AF);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: ClayShadows.searchBar(context),
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? const Color(0xFFF0F1F5) : const Color(0xFF1A1D26),
          fontFamily: 'Outfit',
          fontSize: 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: iconColor, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontFamily: 'Outfit'),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
