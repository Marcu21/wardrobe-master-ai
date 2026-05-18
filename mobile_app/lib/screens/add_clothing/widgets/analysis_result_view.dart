import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'package:mobile_app/widgets/scale_button.dart';
import 'clothing_form.dart';

class AnalysisResultView extends StatelessWidget {
  final Map<String, dynamic>? analysisResult;
  final File? itemImage;
  final TextEditingController categoryController;
  final TextEditingController subCategoryController;
  final TextEditingController materialController;
  final TextEditingController primaryColorController;
  final TextEditingController patternController;
  final TextEditingController brandController;
  final TextEditingController priceController;
  final TextEditingController currencyController;
  final TextEditingController purchaseDateController;
  final TextEditingController fitController;
  final TextEditingController lengthController;
  final TextEditingController necklineController;
  final TextEditingController sleeveLengthController;
  final TextEditingController styleOccasionsController;
  final TextEditingController seasonalityController;
  final TextEditingController careInstructionsController;
  final TextEditingController colorGroupController;
  final TextEditingController maxTempController;
  final String? selectedWardrobeId;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final void Function(String?) onWardrobeChanged;

  const AnalysisResultView({
    super.key,
    required this.analysisResult,
    required this.itemImage,
    required this.categoryController,
    required this.subCategoryController,
    required this.materialController,
    required this.primaryColorController,
    required this.patternController,
    required this.brandController,
    required this.priceController,
    required this.currencyController,
    required this.purchaseDateController,
    required this.fitController,
    required this.lengthController,
    required this.necklineController,
    required this.sleeveLengthController,
    required this.styleOccasionsController,
    required this.seasonalityController,
    required this.careInstructionsController,
    required this.colorGroupController,
    required this.maxTempController,
    required this.selectedWardrobeId,
    required this.onSave,
    required this.onDiscard,
    required this.onWardrobeChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget displayImage;
    if (analysisResult?['image_base64'] != null) {
      try {
        displayImage = Image.memory(
          base64Decode(analysisResult!['image_base64']),
          fit: BoxFit.contain,
          width: double.infinity,
        );
      } catch (_) {
        displayImage = Image.file(
          itemImage!,
          fit: BoxFit.contain,
          width: double.infinity,
        );
      }
    } else {
      displayImage = Image.file(
        itemImage!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    }

    final subCat = subCategoryController.text.isNotEmpty
        ? subCategoryController.text
        : 'Item';
    final brand = brandController.text.isNotEmpty
        ? brandController.text.toUpperCase()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero image
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
                // Photo
                displayImage,

                // Bottom gradient
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

                // Brand + subcategory overlay
                Positioned(
                  bottom: 16,
                  left: 18,
                  right: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brand != null)
                        Text(
                          brand,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 4.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        subCat,
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

                // Category badge top-right
                if (categoryController.text.isNotEmpty)
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
                        categoryController.text,
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

        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section label
              _buildSectionLabel('REVIEW & EDIT', 'Confirm AI details'),
              const SizedBox(height: 16),

              // Form sections
              ClothingForm(
                categoryController: categoryController,
                subCategoryController: subCategoryController,
                materialController: materialController,
                primaryColorController: primaryColorController,
                patternController: patternController,
                brandController: brandController,
                priceController: priceController,
                currencyController: currencyController,
                purchaseDateController: purchaseDateController,
                fitController: fitController,
                lengthController: lengthController,
                necklineController: necklineController,
                sleeveLengthController: sleeveLengthController,
                styleOccasionsController: styleOccasionsController,
                seasonalityController: seasonalityController,
                careInstructionsController: careInstructionsController,
                colorGroupController: colorGroupController,
                maxTempController: maxTempController,
                selectedWardrobeId: selectedWardrobeId,
                onWardrobeChanged: onWardrobeChanged,
              ),

              const SizedBox(height: 20),

              // Save button
              ScaleButton(
                onTap: onSave,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B52F0), Color(0xFF3730C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Save to Wardrobe',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Discard / restart
              ScaleButton(
                onTap: onDiscard,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.arrow_counterclockwise,
                        color: Colors.black54,
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Start over',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String tag, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
