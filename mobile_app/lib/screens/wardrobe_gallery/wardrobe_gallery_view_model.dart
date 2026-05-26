import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';

class WardrobeGalleryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedCategory = 'All';
  String selectedSubCategory = 'All';
  late Stream<QuerySnapshot> clothingStream;

  WardrobeGalleryViewModel() {
    wardrobeStateService.addListener(_onWardrobeChanged);
    _updateStream();
  }

  void _onWardrobeChanged() {
    _updateStream();
    notifyListeners();
  }

  void _updateStream() {
    final currentUserId = AuthService().currentUser?.uid;
    var query = _firestore
        .collection('clothing')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true);

    final activeId = wardrobeStateService.activeWardrobeId;
    if (activeId != null) {
      query = query.where('wardrobe_id', isEqualTo: activeId);
    }

    clothingStream = query.snapshots();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    selectedSubCategory = 'All';
    notifyListeners();
  }

  void selectSubCategory(String subCategory) {
    selectedSubCategory = subCategory;
    notifyListeners();
  }

  @override
  void dispose() {
    wardrobeStateService.removeListener(_onWardrobeChanged);
    super.dispose();
  }
}
