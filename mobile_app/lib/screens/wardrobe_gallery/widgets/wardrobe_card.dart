import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

class WardrobeCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const WardrobeCard({super.key, required this.data, required this.onTap});

  @override
  State<WardrobeCard> createState() => _WardrobeCardState();
}

class _WardrobeCardState extends State<WardrobeCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data['imageUrl'] as String?;
    final brand =
        widget.data['sustainability_info']?['brand'] ?? 'Unknown Brand';
    final subCategory = widget.data['basic_info']?['sub_category'] ?? '';

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
            color: Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SmartClothingImage(imageUrl: imageUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subCategory.toString().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subCategory,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
