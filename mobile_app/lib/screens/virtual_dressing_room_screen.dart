import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/save_outfit_dialog.dart';

class VirtualDressingRoomScreen extends StatefulWidget {
  final List<String>? initialItemIds;

  const VirtualDressingRoomScreen({super.key, this.initialItemIds});

  @override
  State<VirtualDressingRoomScreen> createState() => _VirtualDressingRoomScreenState();
}

class _VirtualDressingRoomScreenState extends State<VirtualDressingRoomScreen> {
  // Lists for each category
  final List<Map<String, dynamic>> _outerwear = [];
  final List<Map<String, dynamic>> _midwear = [];
  final List<Map<String, dynamic>> _tops = [];
  final List<Map<String, dynamic>> _bottoms = [];
  final List<Map<String, dynamic>> _shoes = [];

  // Indices for PageViews - tracked in parent for saving
  int _outerwearIndex = 0;
  int _midwearIndex = 0;
  int _topsIndex = 0;
  int _bottomsIndex = 0;
  int _shoesIndex = 0;

  // Visibility state
  bool _showOuterwear = false;
  bool _showMidwear = false;
  bool _showTops = true;

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
      final List<Map<String, dynamic>> newMidwear = [];
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
        } else if (category.contains('outerwear') || subCategory.contains('jacket') || subCategory.contains('coat')) {
          newOuterwear.add(data);
        } else if (category.contains('midwear') || subCategory.contains('sweater') || subCategory.contains('hoodie') || subCategory.contains('cardigan')) {
          newMidwear.add(data);
        } else if (category.contains('top') || subCategory.contains('shirt') || subCategory.contains('t-shirt')) {
          newTops.add(data);
        } else {
          // Fallback
          newTops.add(data);
        }
      }

      if (mounted) {
        setState(() {
          // Default: maintain zero indices
          _outerwearIndex = 0;
          _midwearIndex = 0;
          _topsIndex = 0;
          _bottomsIndex = 0;
          _shoesIndex = 0;
          
          // Check if we are in REMIX MODE
          if (widget.initialItemIds != null && widget.initialItemIds!.isNotEmpty) {
            // 1. Force ALL optional layers to FALSE initially
            _showOuterwear = false;
            _showMidwear = false;
            _showTops = false; 

            // 2. ONLY set them to true if the item is physically found in the filtered lists
            int foundOuter = newOuterwear.indexWhere((item) => widget.initialItemIds!.contains(item['id']));
            if (foundOuter != -1) {
              final item = newOuterwear.removeAt(foundOuter);
              newOuterwear.insert(0, item);
              _showOuterwear = true;
            }

            int foundMid = newMidwear.indexWhere((item) => widget.initialItemIds!.contains(item['id']));
            if (foundMid != -1) {
              final item = newMidwear.removeAt(foundMid);
              newMidwear.insert(0, item);
              _showMidwear = true;
            }

            int foundTop = newTops.indexWhere((item) => widget.initialItemIds!.contains(item['id']));
            if (foundTop != -1) {
              final item = newTops.removeAt(foundTop);
              newTops.insert(0, item);
              _showTops = true;
            }

            // Do the same find-and-move for Bottoms and Shoes (they are usually always shown, but move them to index 0)
            int foundBottom = newBottoms.indexWhere((item) => widget.initialItemIds!.contains(item['id']));
            if (foundBottom != -1) {
              final item = newBottoms.removeAt(foundBottom);
              newBottoms.insert(0, item);
            }

            int foundShoe = newShoes.indexWhere((item) => widget.initialItemIds!.contains(item['id']));
            if (foundShoe != -1) {
              final item = newShoes.removeAt(foundShoe);
              newShoes.insert(0, item);
            }

          } else {
            // NORMAL MODE (Not a Remix)
            _showTops = true; // Default behavior
            _showOuterwear = false;
            _showMidwear = false;
          }

          _outerwear.clear();
          _midwear.clear();
          _tops.clear();
          _bottoms.clear();
          _shoes.clear();

          _outerwear.addAll(newOuterwear);
          _midwear.addAll(newMidwear);
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
    
    if (_showOuterwear && _outerwear.isNotEmpty) {
      selectedIds.add(_outerwear[_outerwearIndex]['id']);
    }
    if (_showMidwear && _midwear.isNotEmpty) {
      selectedIds.add(_midwear[_midwearIndex]['id']);
    }
    if (_showTops && _tops.isNotEmpty) {
      selectedIds.add(_tops[_topsIndex]['id']);
    }
    
    if (_bottoms.isNotEmpty) {
      selectedIds.add(_bottoms[_bottomsIndex]['id']);
    }
    if (_shoes.isNotEmpty) {
      selectedIds.add(_shoes[_shoesIndex]['id']);
    }

    if (selectedIds.isNotEmpty) {
      SaveOutfitDialog.show(context, itemIds: selectedIds, isAiGenerated: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
    }
  }

  void _openLayersMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Manage Outfit Layers", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Outerwear (Jackets, Coats)'),
                      value: _showOuterwear,
                      activeColor: Colors.black,
                      onChanged: (bool value) {
                        setModalState(() => _showOuterwear = value);
                        setState(() => _showOuterwear = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Midwear (Hoodies, Sweaters)'),
                      value: _showMidwear,
                      activeColor: Colors.black,
                      onChanged: (bool value) {
                        setModalState(() => _showMidwear = value);
                        setState(() => _showMidwear = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Tops (T-Shirts, Shirts)'),
                      value: _showTops,
                      activeColor: Colors.black,
                      onChanged: (bool value) {
                        setModalState(() => _showTops = value);
                        setState(() => _showTops = value);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int fOuter = _showOuterwear ? 4 : 0;
    int fMid = _showMidwear ? 4 : 0;
    int fTop = _showTops ? 3 : 0;
    int fBot = 5;
    int fShoe = 2;

    int activeLayers = 2;
    if (_showOuterwear) activeLayers++;
    if (_showMidwear) activeLayers++;
    if (_showTops) activeLayers++;

    double vpBottoms = activeLayers <= 3 ? 0.75 : 0.60;
    
    double vpTops = activeLayers <= 3 ? 0.65 : 0.50;
    
    double vpMidwear = activeLayers <= 3 ? 0.75 : 0.60;
    
    double vpOuterwear = activeLayers <= 3 ? 0.85 : 0.70;

    double vpShoes = activeLayers <= 3 ? 0.5 : 0.5;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dressing Room", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined, color: Colors.black),
            onPressed: _openLayersMenu,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: _saveOutfit,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        // STRATUL 1: Bottoms & Shoes
                        Column(
                          children: [
                            if (fOuter + fMid + fTop > 0)
                              Spacer(flex: fOuter + fMid + fTop),
                            Expanded(
                              flex: fBot,
                              child: _ClothingCarouselRowInternal(
                                key: ValueKey(vpBottoms),
                                items: _bottoms,
                                onIndexChanged: (index) => _bottomsIndex = index,
                                viewportFraction: vpBottoms,
                              ),
                            ),
                            _ClothingCarouselRow(
                              key: ValueKey(vpShoes),
                              items: _shoes,
                              flex: fShoe,
                              onIndexChanged: (index) => _shoesIndex = index,
                              alignment: Alignment.bottomCenter,
                              viewportFraction: vpShoes,
                            ),
                          ],
                        ),
                        
                        // STRATUL 2: Tops
                        if (_showTops)
                          Column(
                            children: [
                              if (fOuter + fMid > 0)
                                Spacer(flex: fOuter + fMid),
                              _ClothingCarouselRow(
                                key: ValueKey(vpTops),
                                items: _tops,
                                flex: fTop,
                                onIndexChanged: (index) => _topsIndex = index,
                                viewportFraction: vpTops,
                              ),
                              if (fBot + fShoe > 0)
                                Spacer(flex: fBot + fShoe),
                            ],
                          ),

                        // STRATUL 3: Midwear
                        if (_showMidwear)
                          Column(
                            children: [
                              if (fOuter > 0)
                                Spacer(flex: fOuter),
                              _ClothingCarouselRow(
                                key: ValueKey(vpMidwear),
                                items: _midwear,
                                flex: fMid,
                                onIndexChanged: (index) => _midwearIndex = index,
                                viewportFraction: vpMidwear,
                              ),
                              if (fTop + fBot + fShoe > 0)
                                Spacer(flex: fTop + fBot + fShoe),
                            ],
                          ),

                        // STRATUL 4: Outerwear
                        if (_showOuterwear)
                          Column(
                            children: [
                              _ClothingCarouselRow(
                                key: ValueKey(vpOuterwear),
                                items: _outerwear,
                                flex: fOuter,
                                onIndexChanged: (index) => _outerwearIndex = index,
                                viewportFraction: vpOuterwear,
                              ),
                              if (fMid + fTop + fBot + fShoe > 0)
                                Spacer(flex: fMid + fTop + fBot + fShoe),
                            ],
                          ),
                      ],
                    ),
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
    super.key,
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
    super.key,
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
        imageWidget = CachedNetworkImage(
          imageUrl: rawData, 
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
