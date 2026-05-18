import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import '../utils/outfit_sorting_utils.dart';
import 'add_clothing/add_clothing_screen.dart';
import '../widgets/scale_button.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';

class MatchResultScreen extends StatefulWidget {
  final Map<String, dynamic> scannedItemData;
  final File imageFile;

  const MatchResultScreen({
    super.key,
    required this.scannedItemData,
    required this.imageFile,
  });

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  bool _isLoading = true;
  int _matchScore = 0;
  List<String> _pros = [];
  List<String> _cons = [];
  List<Map<String, dynamic>> _generatedOutfits = [];

  @override
  void initState() {
    super.initState();
    _calculateScoreAndOutfits();
  }

  Future<void> _calculateScoreAndOutfits() async {
    try {
      final scannedMetadata =
          widget.scannedItemData['metadata'] as Map<String, dynamic>? ?? {};
      final scannedBasicInfo =
          scannedMetadata['basic_info'] as Map<String, dynamic>? ?? {};
      final scannedStylingInfo =
          scannedMetadata['styling_info'] as Map<String, dynamic>? ?? {};

      // 1. Build Scanned Item JSON payload
      final scannedItemPayload = {
        "item_id": "scanned_new_item",
        "category": scannedBasicInfo['category']?.toString() ?? '',
        "sub_category": scannedBasicInfo['sub_category']?.toString() ?? '',
        "primary_colors": List<String>.from(
          scannedBasicInfo['primary_colors'] ?? [],
        ),
        "style_occasions": List<String>.from(
          scannedStylingInfo['style_occasions'] ?? [],
        ),
        "seasonality": List<String>.from(
          scannedStylingInfo['seasonality'] ?? [],
        ),
      };

      // 2. Fetch User's Wardrobe
      final snapshot = await FirebaseFirestore.instance
          .collection('clothing')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();
      final wardrobeDocs = snapshot.docs;

      List<Map<String, dynamic>> wardrobePayload = [];
      Map<String, Map<String, dynamic>> wardrobeMap = {};

      for (var doc in wardrobeDocs) {
        final data = doc.data();
        wardrobeMap[doc.id] = data;

        final itemBasic = data['basic_info'] as Map<String, dynamic>? ?? {};
        final itemStyling = data['styling_info'] as Map<String, dynamic>? ?? {};

        wardrobePayload.add({
          "item_id": doc.id,
          "category": itemBasic['category']?.toString() ?? '',
          "sub_category": itemBasic['sub_category']?.toString() ?? '',
          "primary_colors": List<String>.from(
            itemBasic['primary_colors'] ?? [],
          ),
          "style_occasions": List<String>.from(
            itemStyling['style_occasions'] ?? [],
          ),
          "seasonality": List<String>.from(itemStyling['seasonality'] ?? []),
        });
      }

      // 3. Make HTTP request to /generate-outfits/
      final apiService = ApiService();
      final uri = Uri.parse('${apiService.baseUrl}/generate-outfits/');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "scanned_item": scannedItemPayload,
          "wardrobe": wardrobePayload,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to generate outfits: ${response.statusCode} - ${response.body}",
        );
      }

      final responseBody = jsonDecode(response.body);

      // 4. Parse response
      final scoreVal = responseBody['score'] ?? 0;
      final prosList = List<String>.from(responseBody['pros'] ?? []);
      final consList = List<String>.from(responseBody['cons'] ?? []);
      final outfitsList = List<dynamic>.from(responseBody['outfits'] ?? []);

      // 5. Build full outfits with image data
      List<Map<String, dynamic>> finalOutfits = [];
      for (var outfit in outfitsList) {
        final outfitName = outfit['outfit_name'] ?? 'Outfit';
        final stylingNotes = outfit['styling_notes'] ?? '';
        final itemIds = List<String>.from(outfit['item_ids'] ?? []);

        List<Map<String, dynamic>> resolvedItems = [];
        for (var id in itemIds) {
          if (id == 'scanned_new_item') {
            resolvedItems.add(widget.scannedItemData);
          } else if (wardrobeMap.containsKey(id)) {
            resolvedItems.add(wardrobeMap[id]!);
          }
        }

        if (resolvedItems.isNotEmpty) {
          finalOutfits.add({
            "outfit_name": outfitName,
            "styling_notes": stylingNotes,
            "items": resolvedItems,
          });
        }
      }

      if (mounted) {
        setState(() {
          _matchScore = (scoreVal as num).toInt();
          _pros = prosList;
          _cons = consList;
          _generatedOutfits = finalOutfits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing wardrobe: $e')));
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score < 50) return const Color(0xFFE53935);
    if (score < 75) return const Color(0xFFE65100);
    return const Color(0xFF00695C);
  }

  Widget _buildAnalysisBox({
    required String title,
    required List<String> items,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedItemHeader() {
    final metadata =
        widget.scannedItemData['metadata'] as Map<String, dynamic>? ?? {};
    final basicInfo = metadata['basic_info'] as Map<String, dynamic>? ?? {};
    final sustainabilityInfo =
        metadata['sustainability_info'] as Map<String, dynamic>? ?? {};

    final brand = sustainabilityInfo['brand'] ?? 'Unknown Brand';
    final subCategory = basicInfo['sub_category'] ?? 'Item';
    final category = basicInfo['category'] ?? '';

    final processedImageBase64 =
        widget.scannedItemData['image_base64'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // ── Hero image card with brand overlay ────────────────────────────
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
                processedImageBase64 != null
                    ? Image.memory(
                        base64Decode(processedImageBase64),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),

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
                      Text(
                        brand.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subCategory,
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
                if (category.toString().isNotEmpty)
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
                            category.toString(),
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
        const SizedBox(height: 20),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Match Results',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.grey[50]!.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanned Item Header
              _buildScannedItemHeader(),

              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _isLoading
                      ? Padding(
                          key: const ValueKey('loading'),
                          padding: const EdgeInsets.symmetric(vertical: 48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.teal.withOpacity(0.07),
                                        border: Border.all(
                                          color: Colors.teal.withOpacity(0.15),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: CircularProgressIndicator(
                                        color: Colors.teal.withOpacity(0.25),
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        color: Colors.teal,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const Icon(
                                      CupertinoIcons.sparkles,
                                      color: Colors.teal,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Analyzing match…",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Scoring, styling & building your results",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          key: const ValueKey('content'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Match Score UI
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _getScoreColor(
                                    _matchScore,
                                  ).withOpacity(0.18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getScoreColor(
                                      _matchScore,
                                    ).withOpacity(0.12),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 88,
                                        height: 88,
                                        child: CircularProgressIndicator(
                                          value: _matchScore / 100,
                                          strokeWidth: 7,
                                          backgroundColor: _getScoreColor(
                                            _matchScore,
                                          ).withOpacity(0.12),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _getScoreColor(_matchScore),
                                              ),
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      Text(
                                        "$_matchScore%",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: _getScoreColor(_matchScore),
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _matchScore >= 75
                                              ? "Great match"
                                              : _matchScore >= 50
                                              ? "Good match"
                                              : "Low match",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: _getScoreColor(_matchScore),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Wardrobe compatibility score",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black45,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Pros UI
                            _buildAnalysisBox(
                              title: "Why it works",
                              items: _pros,
                              color: Colors.green[700]!,
                              bgColor: Colors.green[50]!,
                              icon: Icons.check_circle_outline,
                            ),

                            // Cons UI
                            _buildAnalysisBox(
                              title: "Keep in mind",
                              items: _cons,
                              color: Colors.orange[800]!,
                              bgColor: Colors.orange[50]!,
                              icon: Icons.warning_amber_rounded,
                            ),

                            // Generated Outfits
                            if (_generatedOutfits.isNotEmpty) ...[
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
                              ..._generatedOutfits.map((outfit) {
                                final String name =
                                    outfit['outfit_name'] ?? 'Outfit';
                                final String notes =
                                    outfit['styling_notes'] ?? '';
                                final List<Map<String, dynamic>> items =
                                    List<Map<String, dynamic>>.from(
                                      outfit['items'] ?? [],
                                    );

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          20,
                                          20,
                                          12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
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
                                                padding: const EdgeInsets.only(
                                                  left: 14,
                                                ),
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
                                      // Clothing area (Horizontal Scroll)
                                      SizedBox(
                                        height: 190,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          scrollDirection: Axis.horizontal,
                                          itemCount: items.length,
                                          itemBuilder: (context, index) {
                                            return Row(
                                              children: [
                                                _buildImageThumbnail(
                                                  items[index],
                                                ),
                                                if (index < items.length - 1)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 12,
                                                        ),
                                                    child: Icon(
                                                      Icons.add,
                                                      color:
                                                          Colors.grey.shade300,
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
                            ] else ...[
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    "No outfits could be generated.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),

              // Action Buttons
              const SizedBox(height: 32),
              ScaleButton(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddClothingScreen(
                        initialAnalysisResult: widget.scannedItemData,
                        initialImageFile: widget.imageFile,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Buy & Add to Wardrobe",
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
              ScaleButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.30),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.xmark, color: Colors.teal, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Discard",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

