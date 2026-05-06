import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_service.dart';
import '../services/calendar_service.dart';
import 'virtual_dressing_room_screen.dart';
import '../utils/outfit_sorting_utils.dart';

class OutfitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> outfitData;
  final String outfitId;

  const OutfitDetailScreen({
    super.key,
    required this.outfitData,
    required this.outfitId,
  });

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _nameController;
  late double _currentRating;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outfitData['name'] ?? 'Untitled');
    _currentRating = (widget.outfitData['rating'] ?? 0.0).toDouble();
    _fetchItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    try {
      final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
      final List<String> itemIds = itemIdsDynamic.map((e) => e.toString()).toList();

      if (itemIds.isNotEmpty) {
        final items = await _firebaseService.getItemsByIds(itemIds);
        if (mounted) {
          setState(() {
            _items = OutfitSortingUtils.sortOutfitItems(items);
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
      debugPrint("Error fetching items: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('outfits')
          .doc(widget.outfitId)
          .update({
        'name': _nameController.text.trim(),
        'rating': _currentRating,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    }
  }

  Future<void> _deleteOutfit() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Outfit"),
        content: const Text("Are you sure you want to delete this outfit? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('outfits').doc(widget.outfitId).delete();
        if (mounted) {
          Navigator.pop(context); // Return to Lookbook
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting outfit: $e')),
          );
        }
      }
    }
  }

  Future<void> _logWear() async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final outfitRef = db.collection('outfits').doc(widget.outfitId);
      batch.update(outfitRef, {
        'wear_count': FieldValue.increment(1),
        'wear_dates': FieldValue.arrayUnion([Timestamp.now()]),
      });

      final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
      for (var id in itemIdsDynamic) {
        final itemRef = db.collection('clothing').doc(id.toString());
        
        batch.set(itemRef, {
          'wear_count': FieldValue.increment(1),
          'last_worn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      final calendarService = CalendarService();
      await calendarService.addOutfitEvent(
        widget.outfitData['name'] ?? 'Untitled Outfit',
        DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit logged! Your style history has been updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging wear: $e')),
        );
      }
    }
  }

  Widget _buildLargeImage(Map<String, dynamic> item) {
    final String rawData = item['imageUrl'] ?? '';
    
    // 1. Detectăm categoria ca să știm cât de înaltă să fie poza
    final info = item['basic_info'] ?? {};
    String cat = (info['category'] ?? '').toString().toLowerCase();
    String sub = (info['sub_category'] ?? '').toString().toLowerCase();

    double imageHeight = 200.0; 

    if (cat.contains('bottom') || cat.contains('pant') || sub.contains('jean') || sub.contains('skirt') || sub.contains('dress')) {
      imageHeight = 350.0;
    } else if (cat.contains('outerwear') || sub.contains('coat')) {
      imageHeight = 250.0;
    }
    
    if (rawData.isEmpty) return const SizedBox.shrink();

    Widget imageWidget;
    try {
      if (rawData.startsWith('data:image')) {
        final String base64String = rawData.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else if (rawData.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: rawData,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        imageWidget = const Icon(Icons.checkroom, color: Colors.grey);
      }
    } catch (e) {
      imageWidget = const Icon(Icons.error, color: Colors.grey);
    }
    
    return Container(
      height: imageHeight,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAiGenerated = widget.outfitData['is_ai_generated'] ?? false;
    final Timestamp? createdAt = widget.outfitData['created_at'] as Timestamp?;
    final String dateStr = createdAt != null 
        ? "${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}" 
        : "Unknown date";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Outfit Details", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save Changes",
            onPressed: _saveChanges,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Delete Outfit",
            onPressed: _deleteOutfit,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Visuals
              if (_isLoading)
                const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(child: Text("No items found for this outfit.")),
                )
              else
                ..._items.map(_buildLargeImage),

              const SizedBox(height: 24),

              // 2. Info Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Outfit Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentRating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Metadata Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAiGenerated ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAiGenerated ? Colors.purple.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAiGenerated ? Icons.auto_awesome : Icons.person,
                                  size: 16,
                                  color: isAiGenerated ? Colors.purple : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAiGenerated ? "AI Generated" : "User Created",
                                  style: TextStyle(
                                    color: isAiGenerated ? Colors.purple : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Created on: $dateStr",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Log Wear"),
                      onPressed: _logWear,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black, // Primary button
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text("Remix"),
                      onPressed: () {
                        final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
                        final List<String> itemIds = itemIdsDynamic.map((e) => e.toString()).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VirtualDressingRoomScreen(initialItemIds: itemIds),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
