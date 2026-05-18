import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'shopping_action_buttons.dart';

class ShoppingPreviewView extends StatelessWidget {
  final File imageFile;
  final VoidCallback onAnalyze;
  final VoidCallback onRetake;

  const ShoppingPreviewView({
    super.key,
    required this.imageFile,
    required this.onAnalyze,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Confirm Photo",
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Looks good?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Run the analysis or retake.",
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.14),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Analyze & Match',
              icon: CupertinoIcons.sparkles,
              color: Colors.teal,
              onTap: onAnalyze,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Retake Photo',
              icon: CupertinoIcons.arrow_counterclockwise,
              color: Colors.teal,
              onTap: onRetake,
            ),
          ],
        ),
      ),
    );
  }
}
