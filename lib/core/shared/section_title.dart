import 'package:flutter/material.dart';

class ClaySectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const ClaySectionTitle({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1A1D26);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
          if (action != null) action!,
        ],
      ),
    );
  }
}
