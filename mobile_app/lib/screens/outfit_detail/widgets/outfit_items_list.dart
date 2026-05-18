import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';

class OutfitItemsList extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> items;

  const OutfitItemsList({
    super.key,
    required this.isLoading,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
              const SizedBox(height: 16),
              Text(
                'Loading items…',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.45),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text(
            'No items found for this outfit.',
            style: TextStyle(color: Colors.black.withOpacity(0.45)),
          ),
        ),
      );
    }

    return Column(
      children: items.map(_buildItemImage).toList(),
    );
  }

  Widget _buildItemImage(Map<String, dynamic> item) {
    final String rawData = item['imageUrl'] ?? '';
    final info = item['basic_info'] ?? {};
    final String cat = (info['category'] ?? '').toString().toLowerCase();
    final String sub = (info['sub_category'] ?? '').toString().toLowerCase();

    double imageHeight = 200.0;
    if (cat.contains('bottom') ||
        cat.contains('pant') ||
        sub.contains('jean') ||
        sub.contains('skirt') ||
        sub.contains('dress')) {
      imageHeight = 340.0;
    } else if (cat.contains('outerwear') || sub.contains('coat')) {
      imageHeight = 260.0;
    } else if (sub.contains('hoodie') ||
        sub.contains('sweatshirt') ||
        sub.contains('sweater') ||
        sub.contains('hanorac') ||
        sub.contains('pullover') ||
        sub.contains('jumper')) {
      imageHeight = 240.0;
    }

    if (rawData.isEmpty) return const SizedBox.shrink();

    Widget imageWidget;
    try {
      if (rawData.startsWith('data:image')) {
        final String base64String = rawData.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else if (rawData.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: rawData,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (_, __) => Center(
            child: CircularProgressIndicator(
              color: kPrimary.withOpacity(0.5),
              strokeWidth: 2,
            ),
          ),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        imageWidget = const Center(
          child: Icon(CupertinoIcons.checkmark_circle, color: Colors.grey),
        );
      }
    } catch (e) {
      imageWidget = const Center(child: Icon(Icons.error, color: Colors.grey));
    }

    return Container(
      height: imageHeight,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageWidget,
      ),
    );
  }
}
