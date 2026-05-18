import 'dart:async';
import 'package:flutter/material.dart';

class SmartLoadingDialog extends StatefulWidget {
  const SmartLoadingDialog({super.key});

  @override
  State<SmartLoadingDialog> createState() => _SmartLoadingDialogState();
}

class _SmartLoadingDialogState extends State<SmartLoadingDialog>
    with SingleTickerProviderStateMixin {
  final List<String> _messages = [
    "Analyzing weather...",
    "Selecting best fabrics...",
    "Color matching...",
    "Folding your outfits...",
  ];
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -5 * _controller.value),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.luggage,
                  size: 60,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _messages[_currentIndex],
                  key: ValueKey<int>(_currentIndex),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
