import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/widgets/scale_button.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'widgets/source_picker.dart';
import 'widgets/analysis_loading_view.dart';
import 'widgets/analysis_result_view.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

class AddClothingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAnalysisResult;
  final File? initialImageFile;

  const AddClothingScreen({
    super.key,
    this.initialAnalysisResult,
    this.initialImageFile,
  });

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _itemImage;
  File? _tagImage;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String? _selectedWardrobeId;

  // Basic Info Controllers
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _primaryColorController = TextEditingController();
  final TextEditingController _patternController = TextEditingController();

  // Sustainability Info Controllers
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();

  // Styling Info Controllers
  final TextEditingController _fitController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _necklineController = TextEditingController();
  final TextEditingController _sleeveLengthController = TextEditingController();
  final TextEditingController _styleOccasionsController =
      TextEditingController();
  final TextEditingController _seasonalityController = TextEditingController();

  // Laundry Info Controllers
  final TextEditingController _careInstructionsController =
      TextEditingController();
  final TextEditingController _colorGroupController = TextEditingController();
  final TextEditingController _maxTempController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedWardrobeId = wardrobeStateService.activeWardrobeId;

    if (widget.initialAnalysisResult != null &&
        widget.initialImageFile != null) {
      _analysisResult = widget.initialAnalysisResult;
      _itemImage = widget.initialImageFile;
      if (_analysisResult!['metadata'] != null) {
        _populateForm(_analysisResult!['metadata']);
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subCategoryController.dispose();
    _materialController.dispose();
    _primaryColorController.dispose();
    _patternController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _purchaseDateController.dispose();
    _fitController.dispose();
    _lengthController.dispose();
    _necklineController.dispose();
    _sleeveLengthController.dispose();
    _styleOccasionsController.dispose();
    _seasonalityController.dispose();
    _careInstructionsController.dispose();
    _colorGroupController.dispose();
    _maxTempController.dispose();
    super.dispose();
  }

  List<String> _controllerToList(
    TextEditingController controller, {
    String separator = ',',
  }) {
    if (controller.text.isEmpty) return [];
    if (separator == '\n') {
      return controller.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return controller.text
        .split(separator)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickImage(bool isTag, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );
      if (pickedFile != null) {
        setState(() {
          if (isTag) {
            _tagImage = File(pickedFile.path);
          } else {
            _itemImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImageSourceModal(bool isTag) =>
      showImageSourceModal(context, isTag, _pickImage);

  Future<void> _analyzeItem() async {
    if (_itemImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an item image first.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.processItem(
        _itemImage!,
        tagFile: _tagImage,
      );
      if (result != null && result['metadata'] != null) {
        setState(() {
          _analysisResult = result;
          _populateForm(result['metadata']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(Map<String, dynamic> metadata) {
    if (metadata['basic_info'] != null) {
      _categoryController.text = metadata['basic_info']['category'] ?? '';
      _subCategoryController.text =
          metadata['basic_info']['sub_category'] ?? '';
      _materialController.text = metadata['basic_info']['material'] ?? '';
      _patternController.text = metadata['basic_info']['pattern'] ?? '';
      if (metadata['basic_info']['primary_colors'] != null) {
        _primaryColorController.text =
            (metadata['basic_info']['primary_colors'] as List).join(', ');
      }
    }
    if (metadata['styling_info'] != null) {
      _fitController.text = metadata['styling_info']['fit'] ?? '';
      _lengthController.text = metadata['styling_info']['length'] ?? '';
      _necklineController.text = metadata['styling_info']['neckline'] ?? '';
      _sleeveLengthController.text =
          metadata['styling_info']['sleeve_length'] ?? '';
      if (metadata['styling_info']['style_occasions'] != null) {
        _styleOccasionsController.text =
            (metadata['styling_info']['style_occasions'] as List).join(', ');
      }
      if (metadata['styling_info']['seasonality'] != null) {
        _seasonalityController.text =
            (metadata['styling_info']['seasonality'] as List).join(', ');
      }
    }
    if (metadata['laundry_info'] != null) {
      if (metadata['laundry_info']['care_instructions'] != null) {
        _careInstructionsController.text =
            (metadata['laundry_info']['care_instructions'] as List).join('\n');
      }
      _colorGroupController.text =
          metadata['laundry_info']['color_group'] ?? '';
      _maxTempController.text =
          metadata['laundry_info']['max_temp_celsius']?.toString() ?? '';
    }
    if (metadata['sustainability_info'] != null) {
      _brandController.text = metadata['sustainability_info']['brand'] ?? '';
      _priceController.text =
          metadata['sustainability_info']['price']?.toString() ?? '';
      _currencyController.text =
          metadata['sustainability_info']['currency'] ?? '';
      _purchaseDateController.text =
          metadata['sustainability_info']['purchase_date'] ?? '';
    }
  }

  Future<void> _saveItem() async {
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
                      const Icon(
                        Icons.auto_awesome,
                        color: kPrimary,
                        size: 16,
                      ),
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
    try {
      Map<String, dynamic> finalMetadata = jsonDecode(
        jsonEncode(_analysisResult!['metadata'] ?? {}),
      );

      finalMetadata['basic_info'] = finalMetadata['basic_info'] ?? {};
      finalMetadata['basic_info']['category'] = _categoryController.text;
      finalMetadata['basic_info']['sub_category'] = _subCategoryController.text;
      finalMetadata['basic_info']['material'] = _materialController.text;
      finalMetadata['basic_info']['pattern'] = _patternController.text;
      finalMetadata['basic_info']['primary_colors'] = _controllerToList(
        _primaryColorController,
      );

      finalMetadata['sustainability_info'] =
          finalMetadata['sustainability_info'] ?? {};
      finalMetadata['sustainability_info']['brand'] = _brandController.text;
      final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
      finalMetadata['sustainability_info']['price'] =
          price ??
          (_priceController.text.isEmpty ? null : _priceController.text);
      finalMetadata['sustainability_info']['currency'] =
          _currencyController.text;
      finalMetadata['sustainability_info']['purchase_date'] =
          _purchaseDateController.text;

      finalMetadata['styling_info'] = finalMetadata['styling_info'] ?? {};
      finalMetadata['styling_info']['fit'] = _fitController.text;
      finalMetadata['styling_info']['length'] = _lengthController.text;
      finalMetadata['styling_info']['neckline'] = _necklineController.text;
      finalMetadata['styling_info']['sleeve_length'] =
          _sleeveLengthController.text;
      finalMetadata['styling_info']['style_occasions'] = _controllerToList(
        _styleOccasionsController,
      );
      finalMetadata['styling_info']['seasonality'] = _controllerToList(
        _seasonalityController,
      );

      finalMetadata['laundry_info'] = finalMetadata['laundry_info'] ?? {};
      finalMetadata['laundry_info']['care_instructions'] = _controllerToList(
        _careInstructionsController,
        separator: '\n',
      );
      finalMetadata['laundry_info']['color_group'] = _colorGroupController.text;
      final temp = int.tryParse(_maxTempController.text);
      finalMetadata['laundry_info']['max_temp_celsius'] =
          temp ??
          (_maxTempController.text.isEmpty ? null : _maxTempController.text);

      final Uint8List imageBytes = base64Decode(
        _analysisResult!['image_base64'],
      );
      final String? downloadUrl = await FirebaseService().uploadImageToStorage(
        imageBytes,
        'items',
      );

      if (downloadUrl == null) {
        throw Exception('Failed to upload image to storage.');
      }

      await FirebaseService().saveItem(
        imageUrl: downloadUrl,
        metadata: finalMetadata,
        wardrobeId: _selectedWardrobeId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item saved to Wardrobe!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AnalysisLoadingView();

    return Scaffold(
      backgroundColor: _analysisResult == null ? kBgColor : Colors.grey[50],
      extendBodyBehindAppBar: _analysisResult == null,
      appBar: _analysisResult != null
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
              backgroundColor: Colors.grey[50]!.withOpacity(0.9),
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: _analysisResult == null
          ? SafeArea(
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
                        _buildUploadSection(),
                        const SizedBox(height: 24),
                        _buildAnalyzeButton(),
                      ]),
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
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
                    analysisResult: _analysisResult,
                    itemImage: _itemImage,
                    categoryController: _categoryController,
                    subCategoryController: _subCategoryController,
                    materialController: _materialController,
                    primaryColorController: _primaryColorController,
                    patternController: _patternController,
                    brandController: _brandController,
                    priceController: _priceController,
                    currencyController: _currencyController,
                    purchaseDateController: _purchaseDateController,
                    fitController: _fitController,
                    lengthController: _lengthController,
                    necklineController: _necklineController,
                    sleeveLengthController: _sleeveLengthController,
                    styleOccasionsController: _styleOccasionsController,
                    seasonalityController: _seasonalityController,
                    careInstructionsController: _careInstructionsController,
                    colorGroupController: _colorGroupController,
                    maxTempController: _maxTempController,
                    selectedWardrobeId: _selectedWardrobeId,
                    onSave: _saveItem,
                    onDiscard: () => setState(() {
                      _analysisResult = null;
                      _itemImage = null;
                      _tagImage = null;
                    }),
                    onWardrobeChanged: (val) =>
                        setState(() => _selectedWardrobeId = val),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUploadSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -80,
          right: -60,
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
          top: 60,
          left: -50,
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
        Column(
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
                    image: _itemImage,
                    isMain: true,
                    onTap: () => _showImageSourceModal(false),
                    onClear: () => setState(() => _itemImage = null),
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
                      onTap: _tagImage == null
                          ? () => _showImageSourceModal(true)
                          : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _tagImage != null
                              ? Colors.transparent
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: _tagImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _tagImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _tagImage = null),
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
                    if (_tagImage == null)
                      GestureDetector(
                        onTap: () => _showImageSourceModal(true),
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
        ),
      ],
    );
  }

  Widget _buildUploadCard({
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

  Widget _buildAnalyzeButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ScaleButton(
        onTap: _analyzeItem,
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
