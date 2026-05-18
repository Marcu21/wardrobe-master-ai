import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'shopping_action_buttons.dart';

class ShoppingInitialView extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final VoidCallback onTakePhoto;
  final VoidCallback onGallery;

  const ShoppingInitialView({
    super.key,
    required this.pulseAnimation,
    required this.onTakePhoto,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 24 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: pulseAnimation.value,
                        child: child,
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.22),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.camera,
                          size: 42,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Scan an item.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.teal, Color(0xFF00695C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        "Know instantly.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Analyze any item in-store to see its\nWardrobe Match Score, style fit,\nand sustainability impact.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _FeatureChip(
                          icon: CupertinoIcons.heart,
                          label: 'Style',
                          color: Colors.teal,
                        ),
                        SizedBox(width: 10),
                        _FeatureChip(
                          icon: CupertinoIcons.leaf_arrow_circlepath,
                          label: 'Eco',
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 10),
                        _FeatureChip(
                          icon: CupertinoIcons.star,
                          label: 'Score',
                          color: Color(0xFFE65100),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: 'Take Photo',
                icon: CupertinoIcons.camera_fill,
                color: Colors.teal,
                onTap: onTakePhoto,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Choose from Gallery',
                icon: CupertinoIcons.photo_on_rectangle,
                color: Colors.teal,
                onTap: onGallery,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
