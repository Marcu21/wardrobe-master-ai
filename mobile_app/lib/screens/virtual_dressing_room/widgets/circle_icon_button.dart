import 'package:flutter/material.dart';

class CircleIconButton extends StatefulWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? Colors.deepPurple
                : Colors.white.withOpacity(0.72),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? Colors.deepPurple.withOpacity(0.18)
                    : Colors.black.withOpacity(0.06),
                blurRadius: widget.isPrimary ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.isPrimary ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
