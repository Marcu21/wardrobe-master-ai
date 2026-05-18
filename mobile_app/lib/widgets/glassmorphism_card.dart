import 'dart:ui';
import 'package:flutter/material.dart';

/// Wraps the canonical ClipRRect → BackdropFilter → Container glass-card
/// pattern used throughout the app. Every parameter mirrors the inline value
/// it replaces so callers stay pixel-identical.
class GlassmorphismCard extends StatelessWidget {
  const GlassmorphismCard({
    super.key,
    required this.child,
    this.sigma = 12.0,
    this.colorOpacity = 0.88,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.padding,
    this.margin,
    this.width,
    this.constraints,
  });

  final Widget child;
  final double sigma;
  final double colorOpacity;
  final BorderRadius? borderRadius;

  /// Defaults to [Colors.white] when null.
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          width: width,
          constraints: constraints,
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(colorOpacity),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white,
              width: borderWidth,
            ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
