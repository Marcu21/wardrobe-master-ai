import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/custom_snackbar.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'package:mobile_app/widgets/scale_button.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'add_clothing_view_model.dart';
import 'widgets/source_picker.dart';
import 'widgets/analysis_loading_view.dart';
import 'widgets/analysis_error_view.dart';
import 'widgets/analysis_result_view.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

class AddClothingScreen extends StatelessWidget {
  final Map<String, dynamic>? initialAnalysisResult;
  final File? initialImageFile;

  const AddClothingScreen({
    super.key,
    this.initialAnalysisResult,
    this.initialImageFile,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddClothingViewModel>(
      create: (_) => AddClothingViewModel(
        initialAnalysisResult: initialAnalysisResult,
        initialImageFile: initialImageFile,
        wardrobeId: wardrobeStateService.activeWardrobeId,
      ),
      child: const _AddClothingBody(),
    );
  }
}

class _AddClothingBody extends StatelessWidget {
  const _AddClothingBody();

  void _showImageSourceModal(BuildContext context, bool isTag) {
    final vm = context.read<AddClothingViewModel>();
    showImageSourceModal(
      context,
      isTag,
      (bool isTag, ImageSource source) async {
        try {
          await vm.pickImage(isTag, source);
        } catch (e) {
          if (context.mounted) {
            CustomSnackBar.showError(context, 'Error picking image: $e');
          }
        }
      },
    );
  }

  Future<void> _onAnalyzePressed(BuildContext context) async {
    final vm = context.read<AddClothingViewModel>();
    if (vm.itemImage == null) {
      CustomSnackBar.showInfo(context, 'Please upload an item image first.');
      return;
    }
    await vm.analyzeItem();
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final vm = context.read<AddClothingViewModel>();
    _showSavingDialog(context);
    final String? error = await vm.saveItem();
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss saving dialog
    if (error == null) {
      CustomSnackBar.showSuccess(context, 'Item saved to Wardrobe!');
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(context, 'Failed to save: $error');
    }
  }

  void _showSavingDialog(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
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
                    'Saving to wardrobe',
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
                    'Finding the perfect hanger...',
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
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddClothingViewModel>();

    if (vm.isAnalyzing) return const AnalysisLoadingView();

    if (vm.errorMessage != null) {
      return AnalysisErrorView(
        message: vm.errorMessage!,
        onRetry: () => vm.analyzeItem(),
        onBack: vm.clearError,
      );
    }

    return Scaffold(
      backgroundColor: kBgColor,
      extendBodyBehindAppBar: true,
      appBar: vm.analysisResult != null
          ? AppBar(
              title: const Text(
                'Review & Save',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: vm.analysisResult == null
          ? Stack(
              children: [
                ..._buildBlobs(),
                SafeArea(
                  top: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: false,
                        floating: false,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        foregroundColor: Colors.black87,
                        leading: IconButton(
                          icon: const Icon(
                            CupertinoIcons.back,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text(
                          'Add New Item',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        centerTitle: true,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildUploadSection(context, vm),
                            const SizedBox(height: 24),
                            _buildAnalyzeButton(context),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                ..._buildBlobs(),
                SafeArea(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: AnalysisResultView(
                        analysisResult: vm.analysisResult,
                        itemImage: vm.itemImage,
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
                        selectedWardrobeId: vm.selectedWardrobeId,
                        onSave: () => _onSavePressed(context),
                        onDiscard: vm.resetAnalysis,
                        onWardrobeChanged: vm.setWardrobeId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildBlobs() {
    return [
      Positioned(
        top: -60,
        right: -40,
        child: IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlob1,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 80,
        left: -40,
        child: IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlob2,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildUploadSection(
    BuildContext context,
    AddClothingViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - v)),
            child: Opacity(opacity: v, child: child),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLOTHING ITEM',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add a photo\nto get started.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.15,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 16),
              _buildUploadCard(
                context: context,
                image: vm.itemImage,
                isMain: true,
                onTap: () => _showImageSourceModal(context, false),
                onClear: vm.clearItemImage,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Transform.translate(
            offset: Offset(0, 16 * (1 - v)),
            child: Opacity(opacity: v, child: child),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: vm.tagImage == null
                      ? () => _showImageSourceModal(context, true)
                      : null,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: vm.tagImage != null
                          ? Colors.transparent
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: vm.tagImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  vm.tagImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: vm.clearTagImage,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Icon(
                            CupertinoIcons.tag,
                            size: 26,
                            color: Colors.black38,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Care Tag',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Optional — helps AI read laundry instructions accurately.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.45),
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (vm.tagImage == null)
                  GestureDetector(
                    onTap: () => _showImageSourceModal(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.80),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.10),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required BuildContext context,
    required File? image,
    required bool isMain,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: image == null ? onTap : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: image != null
            ? Container(
                key: ValueKey(image.path),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.12),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        image,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                CupertinoIcons.camera,
                                size: 13,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: onClear,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: const ValueKey('placeholder'),
                height: isMain ? 260 : 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.90),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: kPrimaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.add_circled,
                        size: 28,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to upload photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Camera or gallery',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.35),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAnalyzeButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ScaleButton(
        onTap: () => _onAnalyzePressed(context),
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
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Analyze with AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
