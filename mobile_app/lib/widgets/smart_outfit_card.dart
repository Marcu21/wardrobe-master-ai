import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/outfit_sorting_utils.dart';
import 'smart_clothing_image.dart';

/// A reusable stateful card that fetches outfit items by ID, renders them as a
/// stacked "mannequin" column with dynamic flex values, and composes a card UI
/// from a caller-supplied [footer] and an optional [badge].
class SmartOutfitCard extends StatefulWidget {
  final Map<String, dynamic> outfitData;
  final String outfitId;

  /// The bottom section of the card (e.g. name + rating row, or name + time row).
  final Widget footer;

  /// An optional widget rendered in the top-right of the image area (e.g. AI/You badge).
  final Widget? badge;

  /// Called when the user taps the card.
  final VoidCallback onTap;

  const SmartOutfitCard({
    super.key,
    required this.outfitData,
    required this.outfitId,
    required this.footer,
    required this.onTap,
    this.badge,
  });

  @override
  State<SmartOutfitCard> createState() => _SmartOutfitCardState();
}

class _SmartOutfitCardState extends State<SmartOutfitCard> {
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
      final List<String> itemIds = itemIdsDynamic
          .map((e) => e.toString())
          .toList();

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
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('SmartOutfitCard: error fetching items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Returns the flex value for an item based on its clothing category.
  int _flexForItem(Map<String, dynamic> item) {
    final info = item['basic_info'] ?? {};
    final String cat = (info['category'] ?? '').toString().toLowerCase();
    if (cat.contains('bottom') || cat.contains('pant')) return 4;
    if (cat.contains('shoe') || cat.contains('footwear')) return 2;
    return 3; // tops / outerwear / midwear / default
  }

  Widget _buildMannequin() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_items.isEmpty) {
      return Center(
        child: Icon(Icons.checkroom, size: 40, color: Colors.grey[300]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _items.map((item) {
        return Expanded(
          flex: _flexForItem(item),
          child: SizedBox(
            width: double.infinity,
            child: SmartClothingImage(imageUrl: item['imageUrl']?.toString()),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
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
              // ── Image area ──────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildMannequin()),
                    if (widget.badge != null)
                      Positioned(top: 8, right: 8, child: widget.badge!),
                  ],
                ),
              ),
              // ── Footer (caller-supplied) ─────────────────────────────
              widget.footer,
            ],
          ),
        ),
      ),
    );
  }
}
