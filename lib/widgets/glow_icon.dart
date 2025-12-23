import 'package:flutter/material.dart';

class GlowIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double glowRadius;

  const GlowIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.color,
    this.glowRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
