import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import '../widgets/smart_clothing_image.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF4F3F0);
const _kPurple = Color(0xFF4F46E5);
const _kPurpleLight = Color(0xFFEEEDF8);

class ClothingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const ClothingDetailScreen({super.key, required this.itemData});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  // Basic Info
  late TextEditingController _categoryController;
  late TextEditingController _subCategoryController;
  late TextEditingController _materialController;
  late TextEditingController _primaryColorController;
  late TextEditingController _patternController;

  // Sustainability Info
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _currencyController;
  late TextEditingController _purchaseDateController;

  // Styling Info
  late TextEditingController _fitController;
  late TextEditingController _lengthController;
  late TextEditingController _necklineController;
  late TextEditingController _sleeveLengthController;
  late TextEditingController _styleOccasionsController;
  late TextEditingController _seasonalityController;

  // Laundry Info
  late TextEditingController _careInstructionsController;
  late TextEditingController _colorGroupController;
  late TextEditingController _maxTempController;

  String? _currentWardrobeId;

  @override
  void initState() {
    super.initState();
    final data = widget.itemData;
    final basic = data['basic_info'] as Map<String, dynamic>? ?? {};
    final sust = data['sustainability_info'] as Map<String, dynamic>? ?? {};
    final style = data['styling_info'] as Map<String, dynamic>? ?? {};
    final laundry = data['laundry_info'] as Map<String, dynamic>? ?? {};

    _currentWardrobeId = data['wardrobe_id'];

    _categoryController = TextEditingController(text: basic['category'] ?? '');
    _subCategoryController = TextEditingController(
      text: basic['sub_category'] ?? '',
    );
    _materialController = TextEditingController(text: basic['material'] ?? '');
    _primaryColorController = _listToController(basic['primary_colors']);
    _patternController = TextEditingController(text: basic['pattern'] ?? '');

    _brandController = TextEditingController(text: sust['brand'] ?? '');
    _priceController = TextEditingController(
      text: sust['price']?.toString() ?? '',
    );
    _currencyController = TextEditingController(text: sust['currency'] ?? '');
    _purchaseDateController = TextEditingController(
      text: sust['purchase_date'] ?? '',
    );

    _fitController = TextEditingController(text: style['fit'] ?? '');
    _lengthController = TextEditingController(text: style['length'] ?? '');
    _necklineController = TextEditingController(text: style['neckline'] ?? '');
    _sleeveLengthController = TextEditingController(
      text: style['sleeve_length'] ?? '',
    );
    _styleOccasionsController = _listToController(style['style_occasions']);
    _seasonalityController = _listToController(style['seasonality']);

    _careInstructionsController = _listToController(
      laundry['care_instructions'],
      separator: '\n',
    );
    _colorGroupController = TextEditingController(
      text: laundry['color_group'] ?? '',
    );
    _maxTempController = TextEditingController(
      text: laundry['max_temp_celsius']?.toString() ?? '',
    );
  }

  TextEditingController _listToController(
    dynamic listVal, {
    String separator = ', ',
  }) {
    if (listVal is List) {
      if (listVal.isEmpty) return TextEditingController(text: '');
      return TextEditingController(
        text: listVal.map((e) => e.toString()).join(separator),
      );
    }
    return TextEditingController(text: listVal?.toString() ?? '');
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

  Future<void> _updateItemWardrobe(String? newWardrobeId) async {
    final oldWardrobeId = _currentWardrobeId;
    if (newWardrobeId == oldWardrobeId) return;
    setState(() => _currentWardrobeId = newWardrobeId);
    try {
      await FirebaseService().updateItem(widget.itemData['id'], {
        'wardrobe_id': newWardrobeId,
      });
      String wardrobeName = 'All Wardrobes';
      if (newWardrobeId != null) {
        final matches = wardrobeStateService.wardrobes.where(
          (w) => w['id'] == newWardrobeId,
        );
        if (matches.isNotEmpty) wardrobeName = matches.first['name'];
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item moved to $wardrobeName'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF16A34A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _currentWardrobeId = oldWardrobeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving item: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.12),
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
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with ring
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDC2626).withOpacity(0.08),
                          border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(0.18),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.trash,
                          color: Color(0xFFDC2626),
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
        ),
      ),
    );
    if (confirm == true) _deleteItem();
  }

  Future<void> _deleteItem() async {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.15),
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
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Triple-ring spinner in red
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFDC2626).withOpacity(0.08),
                              border: Border.all(
                                color: const Color(
                                  0xFFDC2626,
                                ).withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              color: const Color(0xFFDC2626).withOpacity(0.3),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: Color(0xFFDC2626),
                              strokeWidth: 2.5,
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.trash,
                            color: Color(0xFFDC2626),
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
        ),
      ),
    );
    try {
      final String docId = widget.itemData['id'];
      final String? imageUrl = widget.itemData['imageUrl'];
      await FirebaseService().deleteItem(docId, imageUrl: imageUrl);
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item deleted successfully'),
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
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateItem() async {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withOpacity(0.15),
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
                  ),
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
                              color: _kPurple.withOpacity(0.08),
                              border: Border.all(
                                color: _kPurple.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              color: _kPurple.withOpacity(0.3),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: _kPurple,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome,
                            color: _kPurple,
                            size: 16,
                          ),
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
        ),
      ),
    );

    try {
      final basicInfo = Map<String, dynamic>.from(
        widget.itemData['basic_info'] ?? {},
      );
      final sustainabilityInfo = Map<String, dynamic>.from(
        widget.itemData['sustainability_info'] ?? {},
      );
      final stylingInfo = Map<String, dynamic>.from(
        widget.itemData['styling_info'] ?? {},
      );
      final laundryInfo = Map<String, dynamic>.from(
        widget.itemData['laundry_info'] ?? {},
      );

      basicInfo['category'] = _categoryController.text;
      basicInfo['sub_category'] = _subCategoryController.text;
      basicInfo['material'] = _materialController.text;
      basicInfo['primary_colors'] = _controllerToList(_primaryColorController);
      basicInfo['pattern'] = _patternController.text;

      sustainabilityInfo['brand'] = _brandController.text;
      if (_priceController.text.isNotEmpty) {
        final price = double.tryParse(
          _priceController.text.replaceAll(',', '.'),
        );
        sustainabilityInfo['price'] = price ?? _priceController.text;
      } else {
        sustainabilityInfo['price'] = null;
      }
      sustainabilityInfo['currency'] = _currencyController.text;
      sustainabilityInfo['purchase_date'] = _purchaseDateController.text;

      stylingInfo['fit'] = _fitController.text;
      stylingInfo['length'] = _lengthController.text;
      stylingInfo['neckline'] = _necklineController.text;
      stylingInfo['sleeve_length'] = _sleeveLengthController.text;
      stylingInfo['style_occasions'] = _controllerToList(
        _styleOccasionsController,
      );
      stylingInfo['seasonality'] = _controllerToList(_seasonalityController);

      laundryInfo['care_instructions'] = _controllerToList(
        _careInstructionsController,
        separator: '\n',
      );
      laundryInfo['color_group'] = _colorGroupController.text;
      if (_maxTempController.text.isNotEmpty) {
        final temp = int.tryParse(_maxTempController.text);
        laundryInfo['max_temp_celsius'] = temp ?? _maxTempController.text;
      } else {
        laundryInfo['max_temp_celsius'] = null;
      }

      await FirebaseService().updateItem(widget.itemData['id'], {
        'basic_info': basicInfo,
        'sustainability_info': sustainabilityInfo,
        'styling_info': stylingInfo,
        'laundry_info': laundryInfo,
      });

      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Details updated successfully!'),
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
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.itemData['imageUrl'] as String?;
    final basic = widget.itemData['basic_info'] as Map<String, dynamic>? ?? {};
    final sust =
        widget.itemData['sustainability_info'] as Map<String, dynamic>? ?? {};
    final subCat = basic['sub_category']?.toString() ?? 'Item';
    final brand = sust['brand']?.toString();
    final category = basic['category']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Item Details',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ScaleButton(
              onTap: _confirmDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.trash,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero image ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 420),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Image
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: _kPurple,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: Colors.black26,
                                size: 48,
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              color: Colors.black26,
                              size: 48,
                            ),
                          ),
                        // Gradient
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
                        // Brand + subcat overlay
                        Positioned(
                          bottom: 16,
                          left: 18,
                          right: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (brand != null && brand.isNotEmpty)
                                Text(
                                  brand.toUpperCase(),
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
                        if (category.isNotEmpty)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
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
                                    ),
                                  ),
                                  child: Text(
                                    category,
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
              ),

              // ── Form sections ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Edit item info',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                        _buildField(
                          'Pattern',
                          _patternController,
                          isLast: true,
                        ),
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

                    // Update button
                    _ScaleButton(
                      onTap: _updateItem,
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
                              color: _kPurple.withOpacity(0.35),
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
                              'Save Changes',
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

                    // Delete button
                    _ScaleButton(
                      onTap: _confirmDelete,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.delete,
                              color: Color(0xFFDC2626),
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Item',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
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
          ),
        ),
      ),
    );
  }

  // ─── Form helpers ─────────────────────────────────────────────────────────

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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _kPurpleLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 14, color: _kPurple),
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
            borderSide: const BorderSide(color: _kPurple, width: 1.5),
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
    return AnimatedBuilder(
      animation: wardrobeStateService,
      builder: (context, _) {
        final wardrobes = wardrobeStateService.wardrobes;
        final isValid =
            _currentWardrobeId == null ||
            wardrobes.any((w) => w['id'] == _currentWardrobeId);
        final dropdownValue = isValid ? _currentWardrobeId : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String?>(
            value: dropdownValue,
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
                borderSide: const BorderSide(color: _kPurple, width: 1.5),
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
            onChanged: (val) => _updateItemWardrobe(val),
          ),
        );
      },
    );
  }
}

// ─── Scale button ─────────────────────────────────────────────────────────────

class _ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _ScaleButton({required this.onTap, required this.child});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─── Dialog button ────────────────────────────────────────────────────────────

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
    final color = widget.isDestructive ? const Color(0xFFDC2626) : _kPurple;

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
