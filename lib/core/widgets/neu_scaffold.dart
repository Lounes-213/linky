import 'package:flutter/material.dart';
import 'neu_button.dart';
import '../theme.dart';

/// A unified neumorphic scaffold that wraps the entire screen.
/// Provides consistent background, safe area, and optional bottom navigation.
class NeuScaffold extends StatelessWidget {
  final Widget body;
  final Widget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const NeuScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = false,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? NeuColors.bg(context);
    return Scaffold(
      backgroundColor: bg,
      appBar: appBar as PreferredSizeWidget?,
      extendBody: extendBody,
      body: SafeArea(
        bottom: !extendBody,
        child: Padding(
          padding: padding,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Neumorphic AppBar with consistent styling.
/// Supports title, actions, back button, and gradient/neumorphic background.
class NeuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double elevation;
  final double height;
  final VoidCallback? onBack;

  const NeuAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation = 0,
    this.height = kToolbarHeight,
    this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? NeuColors.bg(context);

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: bg,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: NeuColors.shadowDark(context).withValues(alpha: 0.3),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Leading
            if (leading != null)
              leading!
            else if (automaticallyImplyLeading && Navigator.of(context).canPop())
              NeuIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => Navigator.of(context).pop(),
                size: 38,
              )
            else if (automaticallyImplyLeading && onBack != null)
              NeuIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
                size: 38,
              )
            else
              const SizedBox(width: 8),

            const SizedBox(width: 8),

            // Title
            Expanded(
              child: titleWidget ??
                  Text(
                    title ?? '',
                    style: TextStyle(
                      color: NeuColors.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),

            // Actions
            if (actions != null) ...actions!,
            if (actions == null) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Neumorphic bottom navigation bar with floating style.
class NeuBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NeuBottomNavItem> items;

  const NeuBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = NeuColors.bg(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: NeuColors.shadowLight(context),
            offset: const Offset(-6, -6),
            blurRadius: 16,
          ),
          BoxShadow(
            color: NeuColors.shadowDark(context),
            offset: const Offset(6, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: LinkyColors.primary,
          unselectedItemColor: NeuColors.textMuted(context),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: items
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon, size: 24),
                  activeIcon: Icon(item.activeIcon ?? item.icon, size: 24),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class NeuBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NeuBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Neumorphic section header with optional action.
class NeuSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NeuSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: NeuColors.text(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: LinkyColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
