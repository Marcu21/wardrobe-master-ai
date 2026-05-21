import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';

class ItemSelectionViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Map<String, dynamic>> _allWardrobeItems = [];
  final Set<String> _selectedIds = {};

  String selectedCategory = 'All';
  String selectedSubCategory = 'All';
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> get allWardrobeItems =>
      List.unmodifiable(_allWardrobeItems);

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  List<Map<String, dynamic>> get filteredDocs {
    return _allWardrobeItems.where((doc) {
      final cat = doc['basic_info']?['category'] as String?;
      final sub = doc['basic_info']?['sub_category'] as String?;
      final matchCategory =
          selectedCategory == 'All' || cat == selectedCategory;
      final matchSubCategory =
          selectedSubCategory == 'All' || sub == selectedSubCategory;
      return matchCategory && matchSubCategory;
    }).toList();
  }

  ItemSelectionViewModel({required List<String> initialSelectedIds}) {
    _selectedIds.addAll(initialSelectedIds);
    wardrobeStateService.addListener(_onWardrobeChanged);
    _listenToWardrobe();
  }

  void _onWardrobeChanged() => _listenToWardrobe();

  void _listenToWardrobe() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      errorMessage = 'User not logged in.';
      isLoading = false;
      notifyListeners();
      return;
    }

    _subscription?.cancel();

    var query = _firestore
        .collection('clothing')
        .where('userId', isEqualTo: currentUser.uid);

    final activeId = wardrobeStateService.activeWardrobeId;
    if (activeId != null) {
      query = query.where('wardrobe_id', isEqualTo: activeId);
    }

    _subscription = query.snapshots().listen(
      (snapshot) {
        _allWardrobeItems = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        errorMessage = 'Failed to load wardrobe. ${error.toString()}';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    selectedSubCategory = 'All';
    notifyListeners();
  }

  void setSubCategory(String subCategory) {
    selectedSubCategory = subCategory;
    notifyListeners();
  }

  @override
  void dispose() {
    wardrobeStateService.removeListener(_onWardrobeChanged);
    _subscription?.cancel();
    super.dispose();
  }
}
