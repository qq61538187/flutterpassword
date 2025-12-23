import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ShineEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShineEffect({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ShineEffect> createState() => _ShineEffectState();
}

class _ShineEffectState extends State<ShineEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ShinePainter(_controller.value),
          child: widget.child,
        );
      },
    );
  }
}

class ShinePainter extends CustomPainter {
  final double progress;

  ShinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-size.width * 0.5 + size.width * progress * 2, 0),
        Offset(size.width * 0.5 + size.width * progress * 2, size.height),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(ShinePainter oldDelegate) => true;
}
