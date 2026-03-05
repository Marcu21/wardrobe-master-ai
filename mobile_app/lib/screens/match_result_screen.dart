import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class MatchResultScreen extends StatefulWidget {
  final Map<String, dynamic> scannedItemData;
  final File imageFile;

  const MatchResultScreen({super.key, required this.scannedItemData, required this.imageFile});

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
      final scannedMetadata = widget.scannedItemData['metadata'] as Map<String, dynamic>? ?? {};
      final scannedBasicInfo = scannedMetadata['basic_info'] as Map<String, dynamic>? ?? {};
      final scannedStylingInfo = scannedMetadata['styling_info'] as Map<String, dynamic>? ?? {};

      // 1. Build Scanned Item JSON payload
      final scannedItemPayload = {
        "item_id": "scanned_new_item",
        "category": scannedBasicInfo['category']?.toString() ?? '',
        "sub_category": scannedBasicInfo['sub_category']?.toString() ?? '',
        "primary_colors": List<String>.from(scannedBasicInfo['primary_colors'] ?? []),
        "style_occasions": List<String>.from(scannedStylingInfo['style_occasions'] ?? []),
        "seasonality": List<String>.from(scannedStylingInfo['seasonality'] ?? []),
      };

      // 2. Fetch User's Wardrobe
      final snapshot = await FirebaseFirestore.instance.collection('clothing').get();
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
          "primary_colors": List<String>.from(itemBasic['primary_colors'] ?? []),
          "style_occasions": List<String>.from(itemStyling['style_occasions'] ?? []),
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
        throw Exception("Failed to generate outfits: ${response.statusCode} - ${response.body}");
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error analyzing wardrobe: $e')));
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score < 50) return Colors.red;
    if (score < 75) return Colors.orange;
    return Colors.green;
  }

  Widget _buildAnalysisBox({required String title, required List<String> items, required Color color, required Color bgColor, required IconData icon}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "•",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.7),
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildScannedItemHeader() {
    final metadata = widget.scannedItemData['metadata'] as Map<String, dynamic>? ?? {};
    final basicInfo = metadata['basic_info'] as Map<String, dynamic>? ?? {};
    final sustainabilityInfo = metadata['sustainability_info'] as Map<String, dynamic>? ?? {};

    final brand = sustainabilityInfo['brand'] ?? 'Unknown Brand';
    final subCategory = basicInfo['sub_category'] ?? 'Item';
    final displayTitle = "$brand - $subCategory";

    final processedImageBase64 = widget.scannedItemData['image_base64'] as String?;

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          width: double.infinity,
          child: processedImageBase64 != null 
              ? Image.memory(
                  base64Decode(processedImageBase64), 
                  fit: BoxFit.contain
                )
              : Image.file(widget.imageFile, fit: BoxFit.contain),
        ),
        const SizedBox(height: 24),
        Text(
          displayTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),
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
        fit: BoxFit.contain
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl, 
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox(width: 80),
        errorWidget: (context, url, error) => const Icon(Icons.error_outline, color: Colors.grey),
      );
    } else {
      imageWidget = const SizedBox(width: 80, child: Icon(Icons.checkroom, color: Colors.grey, size: 40));
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
      appBar: AppBar(
        title: const Text('Match Results', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
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
                            ? const Padding(
                                key: ValueKey('loading'),
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(color: Colors.teal),
                                      SizedBox(height: 16),
                                      Text("Styling with AI...", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                key: const ValueKey('content'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Match Score UI
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(40),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _getScoreColor(_matchScore).withOpacity(0.3), width: 6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getScoreColor(_matchScore).withOpacity(0.15),
                                            blurRadius: 30,
                                            spreadRadius: 10,
                                          )
                                        ]
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            "$_matchScore%",
                                            style: TextStyle(
                                              fontSize: 48, 
                                              fontWeight: FontWeight.w900, 
                                              color: _getScoreColor(_matchScore)
                                            ),
                                          ),
                                          Text(
                                            "Match",
                                            style: TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold, 
                                              color: _getScoreColor(_matchScore).withOpacity(0.8)
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),

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
                                      "Ways to Wear It",
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 16),
                                    ..._generatedOutfits.map((outfit) {
                                      final String name = outfit['outfit_name'] ?? 'Outfit';
                                      final String notes = outfit['styling_notes'] ?? '';
                                      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(outfit['items'] ?? []);

                                      items.sort((a, b) {
                                        int getOrderScore(Map<String, dynamic> item) {
                                          final info = item['metadata']?['basic_info'] ?? item['basic_info'] ?? {};
                                          String cat = (info['category'] ?? '').toString().toLowerCase();
                                          String sub = (info['sub_category'] ?? '').toString().toLowerCase();

                                          if (cat.contains('head') || sub.contains('hat') || sub.contains('cap')) return 0;
                                          if (cat.contains('outerwear') || sub.contains('jacket') || sub.contains('coat')) return 1;
                                          if (cat.contains('midwear') || sub.contains('sweater') || sub.contains('hoodie')) return 2;
                                          if (cat.contains('top') || sub.contains('shirt') || sub.contains('t-shirt')) return 3;
                                          if (cat.contains('bottom') || cat.contains('pant') || sub.contains('jean')) return 4;
                                          if (cat.contains('shoe') || cat.contains('footwear') || sub.contains('sneaker')) return 5;
                                          
                                          return 3;
                                        }
                                        return getOrderScore(a).compareTo(getOrderScore(b));
                                      });
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03), 
                                              blurRadius: 15, 
                                              offset: const Offset(0, 8)
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 4,
                                                        height: 18,
                                                        decoration: BoxDecoration(
                                                          color: Colors.teal,
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                    ],
                                                  ),
                                                  if (notes.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(notes, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.3)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            // Clothing area (Horizontal Scroll)
                                            SizedBox(
                                              height: 190,
                                              child: ListView.builder(
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                scrollDirection: Axis.horizontal,
                                                itemCount: items.length,
                                                itemBuilder: (context, index) {
                                                  return Row(
                                                    children: [
                                                      _buildImageThumbnail(items[index]),
                                                      if (index < items.length - 1)
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 12),
                                                          child: Icon(Icons.add, color: Colors.grey.shade300, size: 24),
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
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added to Wardrobe!')));
                        Navigator.pop(context); // Back to scanner
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Buy & Add to Wardrobe", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  side: const BorderSide(color: Colors.teal, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  "Discard", 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                ),
                              ),
                  ],
                ),
        ),
      ),
    );
  }
}
