import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';

class VirtualDressingRoomViewModel extends ChangeNotifier {
  final List<String>? initialItemIds;

  final List<Map<String, dynamic>> outerwear = [];
  final List<Map<String, dynamic>> midwear = [];
  final List<Map<String, dynamic>> tops = [];
  final List<Map<String, dynamic>> bottoms = [];
  final List<Map<String, dynamic>> shoes = [];

  int outerwearIndex = 0;
  int midwearIndex = 0;
  int topsIndex = 0;
  int bottomsIndex = 0;
  int shoesIndex = 0;

  bool showOuterwear = false;
  bool showMidwear = false;
  bool showTops = true;
  bool isLoading = true;

  bool _disposed = false;

  VirtualDressingRoomViewModel({this.initialItemIds}) {
    wardrobeStateService.addListener(_onWardrobeChanged);
    fetchClothingItems();
  }

  void _onWardrobeChanged() => fetchClothingItems();

  Future<void> fetchClothingItems() async {
    try {
      var query = FirebaseFirestore.instance
          .collection('clothing')
          .where(
            'userId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
          );

      if (wardrobeStateService.activeWardrobeId != null) {
        query = query.where(
          'wardrobe_id',
          isEqualTo: wardrobeStateService.activeWardrobeId,
        );
      }

      final snapshot = await query.get();

      final List<Map<String, dynamic>> newOuterwear = [];
      final List<Map<String, dynamic>> newMidwear = [];
      final List<Map<String, dynamic>> newTops = [];
      final List<Map<String, dynamic>> newBottoms = [];
      final List<Map<String, dynamic>> newShoes = [];

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;

        final Map<String, dynamic> basicInfo = data['basic_info'] ?? {};
        final String category =
            (basicInfo['category'] ?? '').toString().toLowerCase();
        final String subCategory =
            (basicInfo['sub_category'] ?? '').toString().toLowerCase();

        if (category.contains('shoe') || category.contains('footwear')) {
          newShoes.add(data);
        } else if (category.contains('bottom') ||
            category.contains('pant') ||
            subCategory.contains('jean') ||
            subCategory.contains('short')) {
          newBottoms.add(data);
        } else if (category.contains('outerwear') ||
            subCategory.contains('jacket') ||
            subCategory.contains('coat')) {
          newOuterwear.add(data);
        } else if (category.contains('midwear') ||
            subCategory.contains('sweater') ||
            subCategory.contains('hoodie') ||
            subCategory.contains('cardigan')) {
          newMidwear.add(data);
        } else if (category.contains('top') ||
            subCategory.contains('shirt') ||
            subCategory.contains('t-shirt')) {
          newTops.add(data);
        } else {
          newTops.add(data);
        }
      }

      if (!_disposed) {
        outerwearIndex = 0;
        midwearIndex = 0;
        topsIndex = 0;
        bottomsIndex = 0;
        shoesIndex = 0;

        if (initialItemIds != null && initialItemIds!.isNotEmpty) {
          showOuterwear = false;
          showMidwear = false;
          showTops = false;

          final foundOuter = newOuterwear.indexWhere(
            (item) => initialItemIds!.contains(item['id']),
          );
          if (foundOuter != -1) {
            final item = newOuterwear.removeAt(foundOuter);
            newOuterwear.insert(0, item);
            showOuterwear = true;
          }

          final foundMid = newMidwear.indexWhere(
            (item) => initialItemIds!.contains(item['id']),
          );
          if (foundMid != -1) {
            final item = newMidwear.removeAt(foundMid);
            newMidwear.insert(0, item);
            showMidwear = true;
          }

          final foundTop = newTops.indexWhere(
            (item) => initialItemIds!.contains(item['id']),
          );
          if (foundTop != -1) {
            final item = newTops.removeAt(foundTop);
            newTops.insert(0, item);
            showTops = true;
          }

          final foundBottom = newBottoms.indexWhere(
            (item) => initialItemIds!.contains(item['id']),
          );
          if (foundBottom != -1) {
            final item = newBottoms.removeAt(foundBottom);
            newBottoms.insert(0, item);
          }

          final foundShoe = newShoes.indexWhere(
            (item) => initialItemIds!.contains(item['id']),
          );
          if (foundShoe != -1) {
            final item = newShoes.removeAt(foundShoe);
            newShoes.insert(0, item);
          }
        } else {
          showTops = true;
          showOuterwear = false;
          showMidwear = false;
        }

        outerwear
          ..clear()
          ..addAll(newOuterwear);
        midwear
          ..clear()
          ..addAll(newMidwear);
        tops
          ..clear()
          ..addAll(newTops);
        bottoms
          ..clear()
          ..addAll(newBottoms);
        shoes
          ..clear()
          ..addAll(newShoes);

        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching clothing: $e');
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void setShowOuterwear(bool val) {
    showOuterwear = val;
    notifyListeners();
  }

  void setShowMidwear(bool val) {
    showMidwear = val;
    notifyListeners();
  }

  void setShowTops(bool val) {
    showTops = val;
    notifyListeners();
  }

  void setOuterwearIndex(int i) => outerwearIndex = i;
  void setMidwearIndex(int i) => midwearIndex = i;
  void setTopsIndex(int i) => topsIndex = i;
  void setBottomsIndex(int i) => bottomsIndex = i;
  void setShoesIndex(int i) => shoesIndex = i;

  List<String> getSelectedIds() {
    final ids = <String>[];
    if (showOuterwear && outerwear.isNotEmpty) {
      ids.add(outerwear[outerwearIndex]['id']);
    }
    if (showMidwear && midwear.isNotEmpty) {
      ids.add(midwear[midwearIndex]['id']);
    }
    if (showTops && tops.isNotEmpty) {
      ids.add(tops[topsIndex]['id']);
    }
    if (bottoms.isNotEmpty) ids.add(bottoms[bottomsIndex]['id']);
    if (shoes.isNotEmpty) ids.add(shoes[shoesIndex]['id']);
    return ids;
  }

  @override
  void dispose() {
    _disposed = true;
    wardrobeStateService.removeListener(_onWardrobeChanged);
    super.dispose();
  }
}
