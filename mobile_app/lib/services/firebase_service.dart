
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveItem({
    required File itemImage,
    required String imageBase64,
    required Map<String, dynamic> metadata,
  }) async {
    String imageUrl;
    String fileName = 'clothing/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // 1. Try to upload image to Firebase Storage
    try {
      final ref = _storage.ref().child(fileName);
      await ref.putFile(itemImage);
      imageUrl = await ref.getDownloadURL();
      debugPrint("Image uploaded to Storage: $imageUrl");
    } catch (e) {
      debugPrint("Storage upload failed, falling back to base64: $e");
      // Fallback: Use base64 string directly
      imageUrl = 'data:image/png;base64,$imageBase64';
    }

    // 2. Prepare data for Firestore
    Map<String, dynamic> itemData = {
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      ...metadata,
    };

    // 3. Save to Firestore
    try {
      await _firestore.collection('clothing').add(itemData);
      debugPrint("Item saved to Firestore");
    } catch (e) {
      debugPrint("Firestore save failed: $e");
      throw Exception("Failed to save item to wardrobe: $e");
    }
  }

  Future<void> updateItem(String docId, Map<String, dynamic> newMetadata) async {
    try {
      // Create a map to update specific fields without wiping the whole document
      // We assume newMetadata contains the structure for basic_info, styling_info, etc.
      // We might want to flatten it or just merge.
      // Since we are passing the whole structure from the details screen, standard merge is fine.
      
      await _firestore.collection('clothing').doc(docId).update(newMetadata);
      debugPrint("Item updated in Firestore: $docId");
    } catch (e) {
      debugPrint("Firestore update failed: $e");
      throw Exception("Failed to update item: $e");
    }
  }
}
