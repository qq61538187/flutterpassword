import 'package:flutter/material.dart';

/// 优化的容器，使用 RepaintBoundary 来避免 compositing 警告
class OptimizedContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const OptimizedContainer({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: decoration,
      child: child,
    );

    // 如果使用了需要合成的效果（阴影、渐变、模糊等），使用 RepaintBoundary
    if (decoration != null &&
        (decoration!.boxShadow != null ||
            decoration!.gradient != null ||
            decoration!.border != null)) {
      return RepaintBoundary(
        child: container,
      );
    }

    return container;
  }
}
