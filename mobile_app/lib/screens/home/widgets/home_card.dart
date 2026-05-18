import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';

/// Tappable glass card shared by every home-screen navigation card.
class HomeCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color shadowColor;

  const HomeCard({
    super.key,
    required this.onTap,
    required this.child,
    this.shadowColor = kPrimary,
  });

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.14),
                blurRadius: 16,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.07),
                blurRadius: 32,
                spreadRadius: 3,
                offset: Offset.zero,
              ),
            ],
          ),
          child: GlassmorphismCard(
            sigma: 12,
            colorOpacity: 0.92,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(18),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
