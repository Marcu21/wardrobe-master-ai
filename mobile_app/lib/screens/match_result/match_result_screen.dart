import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/add_clothing/add_clothing_screen.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/scale_button.dart';
import 'widgets/match_result_header.dart';
import 'widgets/match_score_card.dart';
import 'widgets/match_analysis_box.dart';
import 'widgets/match_outfits_list.dart';

const _kBlob1 = Color(0x380EA5E9);
const _kBlob2 = Color(0x200284C7);

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
        final itemStyling =
            data['styling_info'] as Map<String, dynamic>? ?? {};

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
          "seasonality": List<String>.from(
            itemStyling['seasonality'] ?? [],
          ),
        });
      }

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

      final scoreVal = responseBody['score'] ?? 0;
      final prosList = List<String>.from(responseBody['pros'] ?? []);
      final consList = List<String>.from(responseBody['cons'] ?? []);
      final outfitsList = List<dynamic>.from(responseBody['outfits'] ?? []);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing wardrobe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
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
            child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MatchResultHeader(
                scannedItemData: widget.scannedItemData,
                imageFile: widget.imageFile,
              ),
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
                                          color:
                                              Colors.teal.withOpacity(0.15),
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
                            MatchScoreCard(matchScore: _matchScore),
                            const SizedBox(height: 20),
                            MatchAnalysisBox(
                              title: "Why it works",
                              items: _pros,
                              color: Colors.green[700]!,
                              bgColor: Colors.green[50]!,
                              icon: Icons.check_circle_outline,
                            ),
                            MatchAnalysisBox(
                              title: "Keep in mind",
                              items: _cons,
                              color: Colors.orange[800]!,
                              bgColor: Colors.orange[50]!,
                              icon: Icons.warning_amber_rounded,
                            ),
                            MatchOutfitsList(
                              generatedOutfits: _generatedOutfits,
                            ),
                          ],
                        ),
                ),
              ),
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
        ],
      ),
    );
  }
}
