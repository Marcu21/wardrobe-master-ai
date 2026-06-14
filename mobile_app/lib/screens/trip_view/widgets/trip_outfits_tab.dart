import 'package:flutter/material.dart';
import 'package:mobile_app/services/packing_service.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';
import 'package:mobile_app/utils/outfit_sorting_utils.dart';

class TripOutfitsTab extends StatelessWidget {
  final CapsuleWardrobe? wardrobe;
  final List<Map<String, dynamic>> clothingItems;
  final Set<int> loadingOutfitIndices;
  final bool isAddingAdHocOutfit;
  final TextEditingController adHocOutfitController;
  final void Function(int) onEditDayOutfit;
  final void Function(String) onAddAdHocOutfit;

  const TripOutfitsTab({
    super.key,
    required this.wardrobe,
    required this.clothingItems,
    required this.loadingOutfitIndices,
    required this.isAddingAdHocOutfit,
    required this.adHocOutfitController,
    required this.onEditDayOutfit,
    required this.onAddAdHocOutfit,
  });

  @override
  Widget build(BuildContext context) {
    if (wardrobe == null || wardrobe!.outfits.isEmpty) {
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)),
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.07),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.deepPurple.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.style_outlined,
                  size: 44,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No outfits yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add clothes to your wardrobe to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 80,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: wardrobe!.outfits.length + 1,
      itemBuilder: (context, index) {
        if (index == wardrobe!.outfits.length) {
          return Container(
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Add another outfit",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: adHocOutfitController,
                          enabled: !isAddingAdHocOutfit,
                          decoration: const InputDecoration(
                            hintText:
                                "Need an outfit for a specific occasion?",
                            hintStyle: TextStyle(fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (val) => onAddAdHocOutfit(val),
                        ),
                      ),
                      isAddingAdHocOutfit
                          ? const Padding(
                              padding: EdgeInsets.all(14.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () => onAddAdHocOutfit(
                                adHocOutfitController.text.trim(),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final outfit = wardrobe!.outfits[index];
        final outfitItems = clothingItems
            .where((item) => outfit.itemIds.contains(item['id']))
            .toList();

        OutfitSortingUtils.sortOutfitItems(outfitItems);

        final isLoading = loadingOutfitIndices.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Outfit ${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                outfit.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          color: Colors.grey[600],
                          onPressed: () => onEditDayOutfit(index),
                        ),
                      ],
                    ),
                  ),
                  if (outfitItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        bottom: 20.0,
                        right: 20.0,
                      ),
                      child: SizedBox(
                        height: 140,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: outfitItems.length,
                          itemBuilder: (context, idx) {
                            final itemInfo = outfitItems[idx];
                            return Row(
                              children: [
                                Container(
                                  width: 110,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SmartClothingImage(
                                      imageUrl:
                                          itemInfo['imageUrl']?.toString(),
                                    ),
                                  ),
                                ),
                                if (idx != outfitItems.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            outfit.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
