import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';

class MatchResultHeader extends StatelessWidget {
  final Map<String, dynamic> scannedItemData;
  final File imageFile;

  const MatchResultHeader({
    super.key,
    required this.scannedItemData,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    final metadata =
        scannedItemData['metadata'] as Map<String, dynamic>? ?? {};
    final basicInfo = metadata['basic_info'] as Map<String, dynamic>? ?? {};
    final sustainabilityInfo =
        metadata['sustainability_info'] as Map<String, dynamic>? ?? {};

    final brand = sustainabilityInfo['brand'] ?? 'Unknown Brand';
    final subCategory = basicInfo['sub_category'] ?? 'Item';
    final category = basicInfo['category'] ?? '';

    final processedImageBase64 =
        scannedItemData['image_base64'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 420),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                processedImageBase64 != null
                    ? Image.memory(
                        base64Decode(processedImageBase64),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Image.file(
                        imageFile,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.52),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 18,
                  right: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subCategory,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (category.toString().isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GlassmorphismCard(
                      sigma: 12,
                      colorOpacity: 0.72,
                      borderRadius: BorderRadius.circular(50),
                      borderColor: Colors.white.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        category.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
