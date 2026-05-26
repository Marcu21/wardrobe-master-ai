import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/widgets/custom_snackbar.dart';
import 'package:mobile_app/widgets/scale_button.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'widgets/clothing_image_header.dart';
import 'widgets/clothing_detail_form.dart';
import 'clothing_detail_view_model.dart';

const _kBlob1 = Color(0x38EC4899);
const _kBlob2 = Color(0x20DB2777);

class ClothingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;
  const ClothingDetailScreen({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClothingDetailViewModel(itemData: itemData),
      child: const _ClothingDetailBody(),
    );
  }
}

class _ClothingDetailBody extends StatelessWidget {
  const _ClothingDetailBody();

  Future<void> _updateItemWardrobe(
    BuildContext context,
    String? newWardrobeId,
  ) async {
    final vm = context.read<ClothingDetailViewModel>();
    final error = await vm.updateItemWardrobe(newWardrobeId);
    if (!context.mounted) return;
    if (error == null) {
      CustomSnackBar.showSuccess(
        context,
        'Item moved to ${vm.currentWardrobeName}',
      );
    } else {
      CustomSnackBar.showError(context, 'Error moving item: $error');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            child: GlassmorphismCard(
              sigma: 24,
              colorOpacity: 0.90,
              borderRadius: BorderRadius.circular(32),
              borderColor: Colors.white.withOpacity(0.8),
              borderWidth: 1.5,
              boxShadow: [
                BoxShadow(
                  color: kDanger.withOpacity(0.12),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kDanger.withOpacity(0.08),
                      border: Border.all(
                        color: kDanger.withOpacity(0.18),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: kDanger,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Delete Item',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogButton(
                          label: 'Cancel',
                          onTap: () => Navigator.pop(ctx, false),
                          isPrimary: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogButton(
                          label: 'Delete',
                          onTap: () => Navigator.pop(ctx, true),
                          isPrimary: true,
                          isDestructive: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirm == true && context.mounted) _deleteItem(context);
  }

  Future<void> _deleteItem(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            child: GlassmorphismCard(
              sigma: 24,
              colorOpacity: 0.90,
              borderRadius: BorderRadius.circular(32),
              borderColor: Colors.white.withOpacity(0.8),
              borderWidth: 1.5,
              boxShadow: [
                BoxShadow(
                  color: kDanger.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kDanger.withOpacity(0.08),
                          border: Border.all(
                            color: kDanger.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: kDanger.withOpacity(0.3),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: kDanger,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.trash,
                        color: kDanger,
                        size: 15,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Deleting item',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Removing from your wardrobe...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final vm = context.read<ClothingDetailViewModel>();
    final error = await vm.deleteItem();
    if (!context.mounted) return;
    Navigator.pop(context);
    if (error == null) {
      CustomSnackBar.showSuccess(context, 'Item deleted successfully');
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(context, 'Error deleting item: $error');
    }
  }

  Future<void> _updateItem(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            child: GlassmorphismCard(
              sigma: 24,
              colorOpacity: 0.90,
              borderRadius: BorderRadius.circular(32),
              borderColor: Colors.white.withOpacity(0.8),
              borderWidth: 1.5,
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimary.withOpacity(0.08),
                          border: Border.all(
                            color: kPrimary.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          color: kPrimary.withOpacity(0.3),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: kPrimary,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: kPrimary, size: 16),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Saving changes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Updating your wardrobe...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final vm = context.read<ClothingDetailViewModel>();
    final error = await vm.updateItem();
    if (!context.mounted) return;
    Navigator.pop(context);
    if (error == null) {
      CustomSnackBar.showSuccess(context, 'Details updated successfully!');
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(context, 'Error updating item: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClothingDetailViewModel>();
    final imageUrl = vm.itemData['imageUrl'] as String?;
    final basic =
        vm.itemData['basic_info'] as Map<String, dynamic>? ?? {};
    final sust =
        vm.itemData['sustainability_info'] as Map<String, dynamic>? ?? {};
    final subCat = basic['sub_category']?.toString() ?? 'Item';
    final brand = sust['brand']?.toString();
    final category = basic['category']?.toString() ?? '';

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    right: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Item Details',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: ScaleButton(
                            onTap: () => _confirmDelete(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFDC2626,
                                ).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFDC2626,
                                  ).withOpacity(0.18),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: kDanger,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClothingImageHeader(
                          imageUrl: imageUrl,
                          subCat: subCat,
                          brand: brand,
                          category: category,
                        ),
                        ClothingDetailForm(
                          categoryController: vm.categoryController,
                          subCategoryController: vm.subCategoryController,
                          materialController: vm.materialController,
                          primaryColorController: vm.primaryColorController,
                          patternController: vm.patternController,
                          brandController: vm.brandController,
                          priceController: vm.priceController,
                          currencyController: vm.currencyController,
                          purchaseDateController: vm.purchaseDateController,
                          fitController: vm.fitController,
                          lengthController: vm.lengthController,
                          necklineController: vm.necklineController,
                          sleeveLengthController: vm.sleeveLengthController,
                          styleOccasionsController: vm.styleOccasionsController,
                          seasonalityController: vm.seasonalityController,
                          careInstructionsController:
                              vm.careInstructionsController,
                          colorGroupController: vm.colorGroupController,
                          maxTempController: vm.maxTempController,
                          currentWardrobeId: vm.currentWardrobeId,
                          onWardrobeChanged: (id) =>
                              _updateItemWardrobe(context, id),
                          onSave: () => _updateItem(context),
                          onDelete: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    this.isDestructive = false,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? kDanger : kPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
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
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: widget.isPrimary ? color : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.isPrimary ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

