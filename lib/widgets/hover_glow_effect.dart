import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HoverGlowEffect extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;

  const HoverGlowEffect({
    super.key,
    required this.child,
    this.glowColor = AppTheme.primaryBlue,
    this.glowRadius = 8,
  });

  @override
  State<HoverGlowEffect> createState() => _HoverGlowEffectState();
}

class _HoverGlowEffectState extends State<HoverGlowEffect>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(
                          alpha: 0.3 * _glowAnimation.value,
                        ),
                        blurRadius: widget.glowRadius * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

