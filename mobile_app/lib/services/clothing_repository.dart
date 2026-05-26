import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ClothingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Wardrobe management ──────────────────────────────────────────────────

  Future<void> createWardrobe(String name) async {
    try {
      await _firestore.collection('wardrobes').add({
        'name': name,
        'userId': _auth.currentUser?.uid,
        'is_default': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      debugPrint("Wardrobe created: $name");
    } catch (e) {
      debugPrint("Failed to create wardrobe: $e");
      throw Exception("Failed to create wardrobe: $e");
    }
  }

  Future<void> updateWardrobe(String wardrobeId, String newName) async {
    try {
      await _firestore
          .collection('wardrobes')
          .doc(wardrobeId)
          .update({'name': newName});
      debugPrint("Wardrobe updated: $wardrobeId");
    } catch (e) {
      debugPrint("Failed to update wardrobe: $e");
      throw Exception("Failed to update wardrobe: $e");
    }
  }

  Future<void> deleteWardrobe(String wardrobeId) async {
    try {
      final batch = _firestore.batch();

      final clothingSnapshot = await _firestore
          .collection('clothing')
          .where('wardrobe_id', isEqualTo: wardrobeId)
          .get();
      for (var doc in clothingSnapshot.docs) {
        batch.update(doc.reference, {'wardrobe_id': null});
      }

      final wardrobeRef =
          _firestore.collection('wardrobes').doc(wardrobeId);
      batch.delete(wardrobeRef);

      await batch.commit();
      debugPrint("Wardrobe deleted: $wardrobeId");
    } catch (e) {
      debugPrint("Failed to delete wardrobe: $e");
      throw Exception("Failed to delete wardrobe: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getWardrobes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('wardrobes')
          .where('userId', isEqualTo: userId)
          .orderBy('created_at')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint("Failed to get wardrobes: $e");
      return [];
    }
  }

  // ── Clothing items ───────────────────────────────────────────────────────

  Future<void> saveItem({
    required String imageUrl,
    required Map<String, dynamic> metadata,
    String? wardrobeId,
  }) async {
    final itemData = {
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser?.uid,
      'wardrobe_id': wardrobeId,
      ...metadata,
    };
    try {
      await _firestore.collection('clothing').add(itemData);
      debugPrint("Item saved to Firestore");
    } catch (e) {
      debugPrint("Firestore save failed: $e");
      throw Exception("Failed to save item to wardrobe: $e");
    }
  }

  Future<void> updateItem(
    String docId,
    Map<String, dynamic> newMetadata, {
    String? wardrobeId,
  }) async {
    try {
      final dataToUpdate = Map<String, dynamic>.from(newMetadata);
      if (wardrobeId != null) dataToUpdate['wardrobe_id'] = wardrobeId;
      await _firestore.collection('clothing').doc(docId).update(dataToUpdate);
      debugPrint("Item updated in Firestore: $docId");
    } catch (e) {
      debugPrint("Firestore update failed: $e");
      throw Exception("Failed to update item: $e");
    }
  }

  Future<void> deleteItem(String docId, {String? imageUrl}) async {
    try {
      if (imageUrl != null &&
          imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
        try {
          final Reference ref = _storage.refFromURL(imageUrl);
          await ref.delete();
          debugPrint("Image deleted from Firebase Storage");
        } catch (e) {
          debugPrint("Failed to delete image: $e");
        }
      }
      await _firestore.collection('clothing').doc(docId).delete();
      debugPrint("Item deleted from Firestore: $docId");
    } catch (e) {
      debugPrint("Firestore delete failed: $e");
      throw Exception("Failed to delete item: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final List<Map<String, dynamic>> items = [];
      for (var i = 0; i < ids.length; i += 10) {
        final end = (i + 10 < ids.length) ? i + 10 : ids.length;
        final chunk = ids.sublist(i, end);
        final querySnapshot = await _firestore
            .collection('clothing')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          items.add(data);
        }
      }
      return items;
    } catch (e) {
      debugPrint("Error fetching items by IDs: $e");
      return [];
    }
  }
}
