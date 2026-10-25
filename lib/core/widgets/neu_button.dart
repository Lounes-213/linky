import 'package:flutter/material.dart';
import '../neu_inset.dart';
import '../theme.dart';

class NeuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor1;
  final Color? iconColor2;

  const NeuButton({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.iconColor1,
    this.iconColor2,
  });

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);
    final txtColor = NeuColors.text(context);
    final iconBg = NeuColors.iconBg(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: sLight, offset: const Offset(-10, -10), blurRadius: 20),
            BoxShadow(color: sDark, offset: const Offset(10, 10), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuInsetShadow(
              borderRadius: 23,
              bgColor: iconBg,
              lightColor: sLight,
              darkColor: sDark,
              offset: const Offset(4, 4),
              blurRadius: 8,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(icon, color: iconColor1 ?? const Color(0xff6C63FF), size: 24),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: txtColor),
            ),
          ],
        ),
      ),
    );
  }
}

class NeuSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const NeuSearchBar({
    super.key,
    this.hintText = 'Rechercher un produit...',
    this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);
    final iconBg = NeuColors.iconBg(context);
    final txtMuted = NeuColors.textMuted(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: sLight, offset: const Offset(-6, -6), blurRadius: 16),
          BoxShadow(color: sDark, offset: const Offset(6, 6), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: txtMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: NeuColors.text(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: txtMuted, fontSize: 14, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (onFilterTap != null)
            GestureDetector(
              onTap: onFilterTap,
              child: NeuInsetShadow(
                borderRadius: 12,
                bgColor: iconBg,
                lightColor: sLight,
                darkColor: sDark,
                offset: const Offset(3, 3),
                blurRadius: 6,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(child: Icon(Icons.tune, color: txtMuted, size: 18)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NeuCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const NeuCard({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.margin,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(color: sLight, offset: const Offset(-10, -10), blurRadius: 20),
            BoxShadow(color: sDark, offset: const Offset(10, 10), blurRadius: 20),
          ],
        ),
        child: child,
      ),
    );
  }
}

class NeuChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const NeuChip({super.key, required this.label, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);
    final txtMuted = NeuColors.textMuted(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xff7B61FF), Color(0xff45C3FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xff7B61FF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              )
            : BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: sLight, offset: const Offset(-4, -4), blurRadius: 10),
                  BoxShadow(color: sDark, offset: const Offset(4, 4), blurRadius: 10),
                ],
              ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isSelected ? Colors.white : txtMuted)),
      ),
    );
  }
}

class NeuTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const NeuTabBar({super.key, required this.tabs, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);
    final txtMuted = NeuColors.textMuted(context);

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: sLight, offset: const Offset(-6, -6), blurRadius: 16),
          BoxShadow(color: sDark, offset: const Offset(6, 6), blurRadius: 16),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xff7B61FF), Color(0xff45C3FF)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xff7B61FF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      )
                    : BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(tabs[i], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isSelected ? Colors.white : txtMuted)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;

  const NeuIconButton({super.key, required this.icon, this.onTap, this.size = 42, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final iconBg = NeuColors.iconBg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);
    final txtColor = NeuColors.text(context);

    return GestureDetector(
      onTap: onTap,
      child: NeuInsetShadow(
        borderRadius: size * 0.4,
        bgColor: iconBg,
        lightColor: sLight,
        darkColor: sDark,
        offset: const Offset(4, 4),
        blurRadius: 8,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: Icon(icon, color: iconColor ?? txtColor, size: size * 0.48)),
        ),
      ),
    );
  }
}

class NeuAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData? icon;

  const NeuAvatar({super.key, this.imageUrl, this.radius = 50, this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);
    final sLight = NeuColors.shadowLight(context);
    final sDark = NeuColors.shadowDark(context);
    final iconBg = NeuColors.iconBg(context);

    return Container(
      width: radius * 2 + 16,
      height: radius * 2 + 16,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: sLight, offset: const Offset(-10, -10), blurRadius: 20),
          BoxShadow(color: sDark, offset: const Offset(10, 10), blurRadius: 20),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: iconBg,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? Icon(icon ?? Icons.person, size: radius, color: NeuColors.textMuted(context))
            : null,
      ),
    );
  }
}
