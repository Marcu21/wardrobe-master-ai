import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SmartClothingImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SmartClothingImage({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return SizedBox(
          width: width,
          height: height,
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.black26,
              ),
            ),
            errorWidget: (context, url, error) =>
                _buildPlaceholderIcon(Icons.broken_image),
          ),
        );
      } else if (imageUrl!.startsWith('data:image')) {
        final base64String = imageUrl!.split(',').last;
        try {
          return SizedBox(
            width: width,
            height: height,
            child: Image.memory(base64Decode(base64String), fit: fit),
          );
        } catch (e) {
          return SizedBox(
            width: width,
            height: height,
            child: _buildPlaceholderIcon(Icons.broken_image),
          );
        }
      } else {
        try {
          return SizedBox(
            width: width,
            height: height,
            child: Image.memory(base64Decode(imageUrl!), fit: fit),
          );
        } catch (e) {
          return SizedBox(
            width: width,
            height: height,
            child: _buildPlaceholderIcon(Icons.image),
          );
        }
      }
    } else {
      return SizedBox(
        width: width,
        height: height,
        child: _buildPlaceholderIcon(Icons.checkroom),
      );
    }
  }

  Widget _buildPlaceholderIcon(IconData icon) {
    return Center(child: Icon(icon, size: 48, color: Colors.black12));
  }
}
