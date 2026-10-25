import 'package:flutter/material.dart';
import 'circle_button.dart';

class ClayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const ClayAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    final txtColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1A1D26);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showBack)
              CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                size: 48,
                iconSize: 18,
              ),
            if (leading != null && !showBack) leading!,
            const SizedBox(width: 12),
            Expanded(
              child: centerTitle
                  ? Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: txtColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    )
                  : Text(
                      title,
                      style: TextStyle(
                        color: txtColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Outfit',
                      ),
                    ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
