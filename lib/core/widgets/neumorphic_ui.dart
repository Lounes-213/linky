import 'package:flutter/material.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool isInnerShadow;
  final double depth;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.isInnerShadow = false,
    this.depth = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF0F0F3); // Standard neumorphic background
    
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isInnerShadow
            ? null
            : [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-depth, -depth),
                  blurRadius: depth * 2,
                ),
                BoxShadow(
                  color: Colors.grey.shade400,
                  offset: Offset(depth, depth),
                  blurRadius: depth * 2,
                ),
              ],
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF0F0F3);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? [] // Inner shadow effect could be added here, but flat is simpler for pressed state
              : [
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}
