import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';

class LoginHeader extends StatelessWidget {
  final bool isLoginMode;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const LoginHeader({
    super.key,
    required this.isLoginMode,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isLoginMode ? 80 : 60,
              height: isLoginMode ? 80 : 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kCtaStart, kCtaEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Wardrobe Master AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your personal AI stylist & digital closet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withOpacity(0.45),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

