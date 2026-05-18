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
import 'package:mobile_app/widgets/animated_loading_step.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'dart:convert';

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

  void _showImageSourceModal(bool isTag) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                24 + MediaQuery.of(ctx).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.9)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isTag ? 'Care Tag Photo' : 'Item Photo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SourceOption(
                          icon: CupertinoIcons.camera_fill,
                          label: 'Camera',
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(isTag, ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SourceOption(
                          icon: CupertinoIcons.photo_on_rectangle,
                          label: 'Gallery',
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(isTag, ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
                      // Animated rings and icon
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
    // Full-screen loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Add New Item',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // Blobs
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
                      color: Color(0x384F46E5),
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
                      color: Color(0x206352D2),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Double ring spinner
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, v, child) =>
                          Opacity(opacity: v, child: child),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimary.withOpacity(0.07),
                              border: Border.all(
                                color: kPrimary.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              color: kPrimary.withOpacity(0.25),
                              strokeWidth: 1.5,
                            ),
                          ),
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              color: kPrimary,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome,
                            color: kPrimary,
                            size: 22,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Title
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, v, child) =>
                          Opacity(opacity: v, child: child),
                      child: const Text(
                        'Analyzing your item…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Animated steps
                    AnimatedLoadingStep(
                      icon: CupertinoIcons.camera_viewfinder,
                      label: 'Reading the item',
                      delay: const Duration(milliseconds: 200),
                      color: kPrimary,
                    ),
                    const SizedBox(height: 14),
                    AnimatedLoadingStep(
                      icon: CupertinoIcons.tag,
                      label: 'Identifying category & brand',
                      delay: const Duration(milliseconds: 700),
                      color: kPrimary,
                    ),
                    const SizedBox(height: 14),
                    AnimatedLoadingStep(
                      icon: CupertinoIcons.color_filter,
                      label: 'Extracting colors & style',
                      delay: const Duration(milliseconds: 1200),
                      color: kPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                  child: _buildResultsView(),
                ),
              ),
            ),
    );
  }

  // Upload section

  Widget _buildUploadSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blobs
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
                  color: Color(0x384F46E5),
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
                  color: Color(0x206352D2),
                ),
              ),
            ),
          ),
        ),
        // Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero upload
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
                  // Label
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

            // Tag upload (secondary)
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
                    // Tag image area
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
                    // Change photo button (bottom left)
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
                    // Remove button (top right)
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

  // Results view

  Widget _buildResultsView() {
    Widget displayImage;
    if (_analysisResult?['image_base64'] != null) {
      try {
        displayImage = Image.memory(
          base64Decode(_analysisResult!['image_base64']),
          fit: BoxFit.contain,
          width: double.infinity,
        );
      } catch (_) {
        displayImage = Image.file(
          _itemImage!,
          fit: BoxFit.contain,
          width: double.infinity,
        );
      }
    } else {
      displayImage = Image.file(
        _itemImage!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    }

    final subCat = _subCategoryController.text.isNotEmpty
        ? _subCategoryController.text
        : 'Item';
    final brand = _brandController.text.isNotEmpty
        ? _brandController.text.toUpperCase()
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
                if (_categoryController.text.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _categoryController.text,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
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
              _buildFormSection(
                icon: CupertinoIcons.info_circle,
                title: 'Basic Info',
                children: [
                  _buildWardrobeDropdown(),
                  _buildField('Category', _categoryController),
                  _buildField('Sub Category', _subCategoryController),
                  _buildField('Material', _materialController),
                  _buildField(
                    'Colors (comma separated)',
                    _primaryColorController,
                  ),
                  _buildField('Pattern', _patternController, isLast: true),
                ],
              ),
              const SizedBox(height: 14),

              _buildFormSection(
                icon: CupertinoIcons.leaf_arrow_circlepath,
                title: 'Sustainability & Purchase',
                children: [
                  _buildField('Brand', _brandController),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          'Price',
                          _priceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          'Currency',
                          _currencyController,
                          isLast: true,
                        ),
                      ),
                    ],
                  ),
                  _buildField(
                    'Purchase Date',
                    _purchaseDateController,
                    hint: 'YYYY-MM-DD',
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildFormSection(
                icon: CupertinoIcons.pencil_outline,
                title: 'Styling',
                children: [
                  _buildField('Fit', _fitController),
                  _buildField('Length', _lengthController),
                  _buildField('Neckline', _necklineController),
                  _buildField('Sleeve Length', _sleeveLengthController),
                  _buildField(
                    'Occasions (comma separated)',
                    _styleOccasionsController,
                  ),
                  _buildField(
                    'Seasonality (comma separated)',
                    _seasonalityController,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildFormSection(
                icon: CupertinoIcons.thermometer,
                title: 'Laundry & Care',
                children: [
                  _buildField(
                    'Care Instructions (one per line)',
                    _careInstructionsController,
                    maxLines: 4,
                  ),
                  _buildField('Color Group', _colorGroupController),
                  _buildField(
                    'Max Temp (°C)',
                    _maxTempController,
                    keyboardType: TextInputType.number,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Save button
              ScaleButton(
                onTap: _saveItem,
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
                onTap: () => setState(() {
                  _analysisResult = null;
                  _itemImage = null;
                  _tagImage = null;
                }),
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

  // Form helpers

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

  Widget _buildFormSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 14, color: kPrimary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: Colors.black.withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 10 : 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.black.withOpacity(0.45),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeDropdown() {
    final wardrobes = wardrobeStateService.wardrobes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        value: _selectedWardrobeId,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Wardrobe',
          labelStyle: TextStyle(
            color: Colors.black.withOpacity(0.45),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Wardrobes'),
          ),
          ...wardrobes.map(
            (w) => DropdownMenuItem<String?>(
              value: w['id'],
              child: Text(w['name']),
            ),
          ),
        ],
        onChanged: (val) => setState(() => _selectedWardrobeId = val),
      ),
    );
  }
}

// Image source option button

class _SourceOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SourceOption> createState() => _SourceOptionState();
}

class _SourceOptionState extends State<_SourceOption> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kPrimaryMid.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 28, color: kPrimary),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

