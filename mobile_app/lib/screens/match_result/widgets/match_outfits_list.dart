import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/utils/outfit_sorting_utils.dart';

class MatchOutfitsList extends StatelessWidget {
  final List<Map<String, dynamic>> generatedOutfits;

  const MatchOutfitsList({super.key, required this.generatedOutfits});

  @override
  Widget build(BuildContext context) {
    if (generatedOutfits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "WAYS TO WEAR IT",
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Outfit combinations",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.teal.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.style_outlined,
                    size: 32,
                    color: Colors.teal.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "No combinations found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add more items to your wardrobe to unlock outfit pairings for this piece.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "WAYS TO WEAR IT",
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4.0,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Outfit combinations",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...generatedOutfits.map((outfit) {
          final String name = outfit['outfit_name'] ?? 'Outfit';
          final String notes = outfit['styling_notes'] ?? '';
          final List<Map<String, dynamic>> items =
              List<Map<String, dynamic>>.from(outfit['items'] ?? []);

          OutfitSortingUtils.sortOutfitItems(items);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.teal.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          _buildImageThumbnail(items[index]),
                          if (index < items.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.add,
                                color: Colors.grey.shade300,
                                size: 24,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }),
      ],
    );
  }
}

Widget _buildImageThumbnail(Map<String, dynamic> item) {
  final imageBase64 = item['image_base64'] as String?;
  final imageUrl = item['imageUrl'] as String?;

  Widget imageWidget;
  if (imageBase64 != null) {
    imageWidget = Image.memory(
      base64Decode(imageBase64),
      fit: BoxFit.contain,
    );
  } else if (imageUrl != null && imageUrl.isNotEmpty) {
    imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const SizedBox(width: 80),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error_outline, color: Colors.grey),
    );
  } else {
    imageWidget = const SizedBox(
      width: 80,
      child: Icon(Icons.checkroom, color: Colors.grey, size: 40),
    );
  }

  return Container(
    height: 160,
    margin: const EdgeInsets.only(right: 12),
    child: imageWidget,
  );
}
