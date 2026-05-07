import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class WardrobeStateService extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _activeWardrobeId;
  List<Map<String, dynamic>> _wardrobes = [];
  bool _isLoading = false;

  StreamSubscription<QuerySnapshot>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  String? get activeWardrobeId => _activeWardrobeId;
  List<Map<String, dynamic>> get wardrobes => _wardrobes;
  bool get isLoading => _isLoading;

  WardrobeStateService() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToWardrobes(user.uid);
      } else {
        _unsubscribeFromWardrobes();
        _wardrobes = [];
        _activeWardrobeId = null;
        notifyListeners();
      }
    });
  }

  void _subscribeToWardrobes(String uid) {
    _unsubscribeFromWardrobes();
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('wardrobes')
        .where('userId', isEqualTo: uid)
        .orderBy('created_at')
        .snapshots()
        .listen(
          (snapshot) {
            _wardrobes = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

            // If active wardrobe ID was deleted or doesn't exist anymore, reset it
            if (_activeWardrobeId != null) {
              final exists = _wardrobes.any(
                (w) => w['id'] == _activeWardrobeId,
              );
              if (!exists) {
                _activeWardrobeId = null;
              }
            }

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error listening to wardrobes: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _unsubscribeFromWardrobes() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _unsubscribeFromWardrobes();
    super.dispose();
  }

  Future<void> createWardrobe(String name) async {
    await _firebaseService.createWardrobe(name);
  }

  Future<void> updateWardrobe(String id, String newName) async {
    await _firebaseService.updateWardrobe(id, newName);
  }

  Future<void> deleteWardrobe(String id) async {
    await _firebaseService.deleteWardrobe(id);
    if (_activeWardrobeId == id) {
      _activeWardrobeId = null;
    }
  }

  void setActiveWardrobe(String? id) {
    _activeWardrobeId = id;
    notifyListeners();
  }
}

// Global singleton instance
final wardrobeStateService = WardrobeStateService();
