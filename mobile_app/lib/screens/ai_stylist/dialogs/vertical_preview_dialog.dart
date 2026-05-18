import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

void showVerticalPreviewDialog(
  BuildContext context,
  List<Map<String, dynamic>> items,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 32,
        ),
        child: GlassmorphismCard(
          sigma: 20,
          colorOpacity: 0.9,
          borderRadius: BorderRadius.circular(32),
          borderColor: kGlassBorder,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 40, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: kPrimary,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Outfit preview",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: items.asMap().entries.expand((entry) {
                          final widgets = <Widget>[
                            Expanded(
                              flex: _getItemFlex(entry.value),
                              child: _buildFullOutfitPreviewImage(entry.value),
                            ),
                          ];
                          if (entry.key < items.length - 1) {
                            widgets.add(const SizedBox(height: 4));
                          }
                          return widgets;
                        }).toList(),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20, top: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

int _getItemFlex(Map<String, dynamic> item) {
  final info = item['metadata']?['basic_info'] ?? item['basic_info'] ?? {};
  String cat = '';
  String sub = '';
  if (item.containsKey('category'))
    cat = item['category'].toString().toLowerCase();
  else if (info is Map && info.containsKey('category'))
    cat = info['category'].toString().toLowerCase();
  if (item.containsKey('sub_category'))
    sub = item['sub_category'].toString().toLowerCase();
  else if (info is Map && info.containsKey('sub_category'))
    sub = info['sub_category'].toString().toLowerCase();

  if (cat.contains('head') ||
      sub.contains('hat') ||
      sub.contains('cap') ||
      sub.contains('beanie'))
    return 1;
  if (cat.contains('outerwear') ||
      sub.contains('jacket') ||
      sub.contains('coat') ||
      sub.contains('blazer'))
    return 3;
  if (cat.contains('midwear') ||
      sub.contains('sweater') ||
      sub.contains('hoodie') ||
      sub.contains('cardigan') ||
      sub.contains('sweatshirt'))
    return 3;
  if (cat.contains('bottom') ||
      cat.contains('pant') ||
      sub.contains('jean') ||
      sub.contains('skirt') ||
      sub.contains('short') ||
      sub.contains('legging'))
    return 4;
  if (cat.contains('shoe') ||
      cat.contains('footwear') ||
      sub.contains('sneaker') ||
      sub.contains('boot') ||
      sub.contains('sandal'))
    return 2;
  return 3;
}

Widget _buildFullOutfitPreviewImage(Map<String, dynamic> item) {
  final imageBase64 = item['image_base64'] as String?;
  final imageUrl = item['imageUrl'] as String?;
  final resolvedUrl = (imageBase64 != null && imageBase64.isNotEmpty)
      ? imageBase64
      : imageUrl;
  return SmartClothingImage(
    imageUrl: resolvedUrl,
    fit: BoxFit.contain,
    width: double.infinity,
  );
}
