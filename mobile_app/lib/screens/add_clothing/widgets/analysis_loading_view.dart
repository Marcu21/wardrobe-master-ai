import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/animated_loading_step.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

class AnalysisLoadingView extends StatelessWidget {
  const AnalysisLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Add New Item',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Blobs
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -40,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Double ring spinner
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, v, child) =>
                        Opacity(opacity: v, child: child),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimary.withOpacity(0.07),
                            border: Border.all(
                              color: kPrimary.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            color: kPrimary.withOpacity(0.25),
                            strokeWidth: 1.5,
                          ),
                        ),
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: kPrimary,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const Icon(
                          Icons.auto_awesome,
                          color: kPrimary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, v, child) =>
                        Opacity(opacity: v, child: child),
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

                  // Animated steps
                  AnimatedLoadingStep(
                    icon: CupertinoIcons.camera_viewfinder,
                    label: 'Reading the item',
                    delay: const Duration(milliseconds: 200),
                    color: kPrimary,
                  ),
                  const SizedBox(height: 14),
                  AnimatedLoadingStep(
                    icon: CupertinoIcons.tag,
                    label: 'Identifying category & brand',
                    delay: const Duration(milliseconds: 700),
                    color: kPrimary,
                  ),
                  const SizedBox(height: 14),
                  AnimatedLoadingStep(
                    icon: CupertinoIcons.color_filter,
                    label: 'Extracting colors & style',
                    delay: const Duration(milliseconds: 1200),
                    color: kPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
