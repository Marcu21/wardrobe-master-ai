import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/save_outfit_dialog.dart';

class VirtualDressingRoomScreen extends StatefulWidget {
  const VirtualDressingRoomScreen({super.key});

  @override
  State<VirtualDressingRoomScreen> createState() => _VirtualDressingRoomScreenState();
}

class _VirtualDressingRoomScreenState extends State<VirtualDressingRoomScreen> {
  // Lists for each category
  final List<Map<String, dynamic>> _outerwear = [];
  final List<Map<String, dynamic>> _tops = [];
  final List<Map<String, dynamic>> _bottoms = [];
  final List<Map<String, dynamic>> _shoes = [];

  // Indices for PageViews - tracked in parent for saving
  int _outerwearIndex = 0;
  int _topsIndex = 0;
  int _bottomsIndex = 0;
  int _shoesIndex = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClothingItems();
  }

  Future<void> _fetchClothingItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('clothing').get();

      // Temporary lists
      final List<Map<String, dynamic>> newOuterwear = [];
      final List<Map<String, dynamic>> newTops = [];
      final List<Map<String, dynamic>> newBottoms = [];
      final List<Map<String, dynamic>> newShoes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Keep the ID
        
        // Safely extract category and sub_category
        Map<String, dynamic> basicInfo = data['basic_info'] ?? {};
        String category = (basicInfo['category'] ?? '').toString().toLowerCase();
        String subCategory = (basicInfo['sub_category'] ?? '').toString().toLowerCase();

        // Grouping logic (robust matching)
        if (category.contains('shoe') || category.contains('footwear')) {
          newShoes.add(data);
        } else if (category.contains('bottom') || category.contains('pant') || subCategory.contains('jean') || subCategory.contains('short')) {
          newBottoms.add(data);
        } else if (category.contains('outerwear') || subCategory.contains('jacket') || subCategory.contains('coat') || subCategory.contains('hoodie')) {
          newOuterwear.add(data);
        } else if (category.contains('top') || subCategory.contains('shirt') || subCategory.contains('sweater') || subCategory.contains('t-shirt')) {
          newTops.add(data);
        } else {
          // Fallback
          newTops.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _outerwear.clear();
          _tops.clear();
          _bottoms.clear();
          _shoes.clear();

          _outerwear.addAll(newOuterwear);
          _tops.addAll(newTops);
          _bottoms.addAll(newBottoms);
          _shoes.addAll(newShoes);

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching clothing: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveOutfit() {
    final selectedIds = <String>[];
    
    if (_outerwear.isNotEmpty) selectedIds.add(_outerwear[_outerwearIndex]['id']);
    if (_tops.isNotEmpty) selectedIds.add(_tops[_topsIndex]['id']);
    if (_bottoms.isNotEmpty) selectedIds.add(_bottoms[_bottomsIndex]['id']);
    if (_shoes.isNotEmpty) selectedIds.add(_shoes[_shoesIndex]['id']);

    if (selectedIds.isNotEmpty) {
      SaveOutfitDialog.show(context, itemIds: selectedIds, isAiGenerated: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean background
      appBar: AppBar(
        title: const Text("Dressing Room", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: _saveOutfit,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _ClothingCarouselRow(
                    items: _outerwear,
                    flex: 4,
                    onIndexChanged: (index) => _outerwearIndex = index,
                  ),
                  _ClothingCarouselRow(
                    items: _tops,
                    flex: 3,
                    onIndexChanged: (index) => _topsIndex = index,
                  ),
                  Expanded(
                    flex: 5, // Increased flex for Bottoms (Pants usually longer)
                    child: Transform.translate(
                      offset: const Offset(0, -20), // Gently pull pants up
                      child: _ClothingCarouselRowInternal(
                        items: _bottoms,
                        onIndexChanged: (index) => _bottomsIndex = index,
                      ),
                    ),
                  ),
                  // Shoes - No transform, aligned to bottom
                  _ClothingCarouselRow(
                    items: _shoes,
                    flex: 2,
                    onIndexChanged: (index) => _shoesIndex = index,
                    alignment: Alignment.bottomCenter, // Sit on the floor/bottom
                    viewportFraction: 0.5,
                  ),
                ],
              ),
      ),
    );
  }
}

// Wrapper to handle flex in the main column naturally
class _ClothingCarouselRow extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int flex;
  final Function(int) onIndexChanged;
  final Alignment alignment;
  final double viewportFraction;

  const _ClothingCarouselRow({
    required this.items,
    required this.flex,
    required this.onIndexChanged,
    this.alignment = Alignment.center,
    this.viewportFraction = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: _ClothingCarouselRowInternal(
        items: items, 
        onIndexChanged: onIndexChanged,
        alignment: alignment,
        viewportFraction: viewportFraction,
      ),
    );
  }
}

// The core carousel widget
class _ClothingCarouselRowInternal extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(int) onIndexChanged;
  final Alignment alignment;
  final double viewportFraction;

  const _ClothingCarouselRowInternal({
    required this.items,
    required this.onIndexChanged,
    this.alignment = Alignment.center,
    this.viewportFraction = 0.6,
  });

  @override
  State<_ClothingCarouselRowInternal> createState() => _ClothingCarouselRowInternalState();
}

class _ClothingCarouselRowInternalState extends State<_ClothingCarouselRowInternal> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildClothingItem(Map<String, dynamic> item) {
    String rawData = item['imageUrl'] ?? '';
    Widget imageWidget;

    try {
      if (rawData.startsWith('data:image')) {
        final String base64String = rawData.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64String), 
          fit: BoxFit.contain, // Maximize size, no cropping
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      } else if (rawData.startsWith('http')) {
        imageWidget = Image.network(
          rawData, 
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      } else {
        imageWidget = const Icon(Icons.checkroom, size: 50, color: Colors.grey);
      }
    } catch (e) {
       imageWidget = const Icon(Icons.error, size: 50, color: Colors.red);
    }

    // Centering or alignment passed from parent
    return Container(
      alignment: widget.alignment,
      width: double.infinity,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          "Empty",
          style: TextStyle(color: Colors.grey[300], fontSize: 12),
        ),
      );
    }

    return PageView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      onPageChanged: widget.onIndexChanged,
      physics: const BouncingScrollPhysics(),
      padEnds: true, // centered item
      itemBuilder: (context, index) {
        return _buildClothingItem(widget.items[index]);
      },
    );
  }
}
