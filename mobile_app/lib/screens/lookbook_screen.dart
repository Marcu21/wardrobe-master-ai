import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'outfit_detail_screen.dart';

class LookbookScreen extends StatelessWidget {
  const LookbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Outfits",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child:StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('outfits')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No saved outfits yet.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.35, // Tall cards for 2x2 layout
              crossAxisSpacing: 12, // Slightly tighter spacing
              mainAxisSpacing: 12,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return OutfitGridCard(outfitData: data, outfitId: doc.id);
            },
          );
        },
      ),
    )
    );
  }
}

class OutfitGridCard extends StatefulWidget {
  final Map<String, dynamic> outfitData;
  final String outfitId;

  const OutfitGridCard({super.key, required this.outfitData, required this.outfitId});

  @override
  State<OutfitGridCard> createState() => _OutfitGridCardState();
}

class _OutfitGridCardState extends State<OutfitGridCard> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
      final List<String> itemIds = itemIdsDynamic.map((e) => e.toString()).toList();

      if (itemIds.isNotEmpty) {
        final items = await _firebaseService.getItemsByIds(itemIds);
        if (mounted) {
          setState(() {
            _items = _sortItems(items);
            _isLoading = false;
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching outfit items: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _sortItems(List<Map<String, dynamic>> items) {
    // Helper to get score
    int getScore(Map<String, dynamic> item) {
      final info = item['basic_info'] ?? {};
      String cat = (info['category'] ?? '').toString().toLowerCase();
      String sub = (info['sub_category'] ?? '').toString().toLowerCase();

      if (cat.contains('head') || sub.contains('hat') || sub.contains('cap')) return 0; // Head
      if (cat.contains('outerwear') || sub.contains('jacket') || sub.contains('coat')) return 1; // Outer
      if (cat.contains('top') || sub.contains('shirt') || sub.contains('blouse') || sub.contains('sweater')) return 2; // Tops
      if (cat.contains('bottom') || cat.contains('pant') || sub.contains('jean') || sub.contains('skirt') || sub.contains('short')) return 3; // Bottoms
      if (cat.contains('shoe') || cat.contains('footwear') || sub.contains('sneaker') || sub.contains('boot')) return 4; // Shoes
      
      return 2; // Default to Top/Middle if unknown
    }

    items.sort((a, b) => getScore(a).compareTo(getScore(b)));
    return items;
  }

  Widget _buildThumbnail(Map<String, dynamic> item) {
    final String rawData = item['imageUrl'] ?? '';
    
    if (rawData.isEmpty) { // Empty placeholder
      return const SizedBox.shrink(); 
    }

    Widget imageWidget;
    try {
      if (rawData.startsWith('data:image')) {
        final String base64String = rawData.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain, // Changed to contain for full item visibility
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else if (rawData.startsWith('http')) {
        imageWidget = Image.network(
          rawData,
          fit: BoxFit.contain,
           alignment: Alignment.center,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
         imageWidget = const Icon(Icons.checkroom, color: Colors.grey);
      }
    } catch (e) {
      imageWidget = const Icon(Icons.error, color: Colors.grey);
    }
    
    return Container(
      width: double.infinity,
      child: imageWidget,
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.outfitData['name'] ?? 'Untitled';
    final double rating = (widget.outfitData['rating'] ?? 0.0).toDouble();
    final bool isAiGenerated = widget.outfitData['is_ai_generated'] ?? false;
    final Timestamp? createdAt = widget.outfitData['created_at'] as Timestamp?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutfitDetailScreen(
              outfitData: widget.outfitData,
              outfitId: widget.outfitId,
            ),
          ),
        );
      },
      child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      // Subtle gradient background via Container
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stack for Image Column + Badge
            Expanded(
            child: Stack(
              children: [
                // "Mannequin" Column
                Positioned.fill(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : _items.isEmpty
                          ? Center(
                              child: Icon(Icons.checkroom, size: 40, color: Colors.grey[300]),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _items.map((item) {
                                // Dynamic Flex implementation
                                int flex = 3; // Default for Tops/Outerwear
                                final info = item['basic_info'] ?? {};
                                String cat = (info['category'] ?? '').toString().toLowerCase();
                                
                                if (cat.contains('bottom') || cat.contains('pant')) {
                                  flex = 4; // More space for pants
                                } else if (cat.contains('shoe') || cat.contains('footwear')) {
                                  flex = 2; // Less space for shoes
                                }
                                
                                return Expanded(
                                  flex: flex,
                                  child: Container(
                                    // Removed horizontal padding for connected look
                                    padding: EdgeInsets.zero, 
                                    child: _buildThumbnail(item)
                                  ),
                                );
                              }).toList(),
                            ),
                ),

                // Smart Badge (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAiGenerated ? Colors.purple.withValues(alpha: 0.9) : Colors.blue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                         BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAiGenerated ? Icons.auto_awesome : Icons.person,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAiGenerated ? "AI" : "You",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // More compact padding
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Slightly smaller font
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    )
  );
  
  }
}
