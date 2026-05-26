import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/services/clothing_repository.dart';
import 'package:mobile_app/services/calendar_service.dart';
import 'package:mobile_app/utils/outfit_sorting_utils.dart';

class OutfitDetailViewModel extends ChangeNotifier {
  final Map<String, dynamic> outfitData;
  final String outfitId;

  late final TextEditingController nameController;
  double currentRating;
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  int wearCount;

  bool _disposed = false;

  OutfitDetailViewModel({required this.outfitData, required this.outfitId})
    : currentRating = (outfitData['rating'] ?? 0.0).toDouble(),
      wearCount = (outfitData['wear_count'] ?? 0) as int {
    nameController = TextEditingController(
      text: outfitData['name'] ?? 'Untitled',
    );
    _fetchItems();
  }

  void setRating(double rating) {
    currentRating = rating;
    notifyListeners();
  }

  Future<void> _fetchItems() async {
    try {
      final List<dynamic> itemIdsDynamic = outfitData['item_ids'] ?? [];
      final List<String> itemIds =
          itemIdsDynamic.map((e) => e.toString()).toList();
      if (itemIds.isNotEmpty) {
        final fetched = await ClothingRepository().getItemsByIds(itemIds);
        if (!_disposed) {
          items = OutfitSortingUtils.sortOutfitItems(fetched);
          isLoading = false;
          notifyListeners();
        }
      } else {
        if (!_disposed) {
          isLoading = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching items: $e');
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<String?> saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('outfits')
          .doc(outfitId)
          .update({
            'name': nameController.text.trim(),
            'rating': currentRating,
          });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteOutfit() async {
    try {
      await FirebaseFirestore.instance
          .collection('outfits')
          .doc(outfitId)
          .delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> logWear() async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final outfitRef = db.collection('outfits').doc(outfitId);
      batch.update(outfitRef, {
        'wear_count': FieldValue.increment(1),
        'wear_dates': FieldValue.arrayUnion([Timestamp.now()]),
      });

      final List<dynamic> itemIdsDynamic = outfitData['item_ids'] ?? [];
      for (var id in itemIdsDynamic) {
        final itemRef = db.collection('clothing').doc(id.toString());
        batch.set(
          itemRef,
          {'wear_count': FieldValue.increment(1), 'last_worn': Timestamp.now()},
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await CalendarService().addOutfitEvent(
        outfitData['name'] ?? 'Untitled Outfit',
        DateTime.now(),
      );

      if (!_disposed) {
        wearCount++;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    super.dispose();
  }
}
