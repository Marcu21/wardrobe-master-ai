import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/animated_loading_step.dart';

class ShoppingLoadingView extends StatelessWidget {
  const ShoppingLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, v, child) => Opacity(opacity: v, child: child),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.withOpacity(0.07),
                      border: Border.all(
                        color: Colors.teal.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      color: Colors.teal.withOpacity(0.25),
                      strokeWidth: 1.5,
                    ),
                  ),
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.teal,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, v, child) => Opacity(opacity: v, child: child),
              child: const Text(
                'Analyzing your item…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedLoadingStep(
              icon: CupertinoIcons.camera_viewfinder,
              label: 'Reading the item',
              delay: const Duration(milliseconds: 200),
              color: Colors.teal,
            ),
            const SizedBox(height: 14),
            AnimatedLoadingStep(
              icon: CupertinoIcons.tag,
              label: 'Identifying category & brand',
              delay: const Duration(milliseconds: 700),
              color: Colors.teal,
            ),
            const SizedBox(height: 14),
            AnimatedLoadingStep(
              icon: CupertinoIcons.color_filter,
              label: 'Extracting colors & style',
              delay: const Duration(milliseconds: 1200),
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
