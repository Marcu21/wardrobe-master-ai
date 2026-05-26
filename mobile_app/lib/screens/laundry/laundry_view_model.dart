import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/laundry_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';

class LaundryViewModel extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final LaundryService _laundryService = LaundryService();
  bool _testMode = false;

  List<Map<String, dynamic>> allWardrobeItems = [];
  final List<Map<String, dynamic>> _basketItems = [];
  String selectedCategory = 'All';
  String selectedSubCategory = 'All';
  bool isLoading = true;
  String? errorMessage;

  StreamSubscription<QuerySnapshot>? _wardrobeSubscription;

  List<Map<String, dynamic>> get basketItems => List.unmodifiable(_basketItems);

  LaundryService get laundryService => _laundryService;

  LaundryAnalysisResult get analysisResult =>
      _laundryService.analyzeBasket(_basketItems);

  List<Map<String, dynamic>> get filteredDocs {
    final Set<String> basketIds =
        _basketItems.map((e) => e['id'] as String).toSet();
    return allWardrobeItems.where((doc) {
      if (basketIds.contains(doc['id'])) return false;
      final cat = doc['basic_info']?['category'] as String?;
      final sub = doc['basic_info']?['sub_category'] as String?;
      return (selectedCategory == 'All' || cat == selectedCategory) &&
          (selectedSubCategory == 'All' || sub == selectedSubCategory);
    }).toList();
  }

  LaundryViewModel() {
    wardrobeStateService.addListener(_onWardrobeChanged);
    _listenToWardrobe();
  }

  /// Test-only constructor — bypasses Firebase subscription entirely.
  @visibleForTesting
  LaundryViewModel.forTest() {
    _testMode = true;
    isLoading = false;
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

    _wardrobeSubscription?.cancel();

    var query = _firestore
        .collection('clothing')
        .where('userId', isEqualTo: currentUser.uid);

    final activeId = wardrobeStateService.activeWardrobeId;
    if (activeId != null) {
      query = query.where('wardrobe_id', isEqualTo: activeId);
    }

    _wardrobeSubscription = query.snapshots().listen(
      (snapshot) {
        final items = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        allWardrobeItems = items;

        final dbDirtyItems = items.where((item) {
          final status = item['status']?.toString().toLowerCase();
          final isDirty =
              item['is_dirty'] == true || item['isDirty'] == true;
          return status == 'dirty' || status == 'laundry' || isDirty;
        }).toList();

        for (var dirty in dbDirtyItems) {
          if (!_basketItems.any((b) => b['id'] == dirty['id'])) {
            _basketItems.add(dirty);
          }
        }

        _basketItems.removeWhere((basketItem) {
          final serverItem = items.firstWhere(
            (i) => i['id'] == basketItem['id'],
            orElse: () => <String, dynamic>{},
          );
          if (serverItem.isEmpty) return true;
          final status = serverItem['status']?.toString().toLowerCase();
          return status == 'clean' ||
              serverItem['is_dirty'] == false ||
              serverItem['isDirty'] == false;
        });

        isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        errorMessage =
            'Failed to load wardrobe realtime. ${error.toString()}';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void addToBasket(Map<String, dynamic> item) {
    _basketItems.add(item);
    notifyListeners();
  }

  void removeFromBasket(Map<String, dynamic> item) {
    _basketItems.removeWhere((e) => e['id'] == item['id']);
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
    if (!_testMode) wardrobeStateService.removeListener(_onWardrobeChanged);
    _wardrobeSubscription?.cancel();
    super.dispose();
  }
}
