import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OutfitRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<String> saveOutfit(Map<String, dynamic> outfitData) async {
    try {
      final data = {
        ...outfitData,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': _auth.currentUser?.uid ?? 'unknown_user',
      };
      final docRef = await _firestore.collection('outfits').add(data);
      debugPrint("Outfit saved to Firestore: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint("Failed to save outfit: $e");
      throw Exception("Failed to save outfit: $e");
    }
  }

  Future<void> logWearExistingOutfit(
    String outfitId,
    List<String> itemIds,
  ) async {
    try {
      final batch = _firestore.batch();

      final outfitRef = _firestore.collection('outfits').doc(outfitId);
      batch.update(outfitRef, {
        'wear_count': FieldValue.increment(1),
        'wear_dates': FieldValue.arrayUnion([Timestamp.now()]),
      });

      for (final itemId in itemIds) {
        final itemRef = _firestore.collection('clothing').doc(itemId);
        batch.update(itemRef, {'last_worn': FieldValue.serverTimestamp()});
      }

      await batch.commit();
      debugPrint("Outfit wear logged for: $outfitId");
    } catch (e) {
      debugPrint("Failed to log wear for outfit: $e");
      throw Exception("Failed to log wear for outfit: $e");
    }
  }

  Future<void> saveOutfitFeedback({
    required List<String> itemIds,
    required String userPrompt,
    required String weatherContext,
    required bool isLike,
    String? dislikeReason,
  }) async {
    try {
      final data = {
        'item_ids': itemIds,
        'user_prompt': userPrompt,
        'weather_context': weatherContext,
        'is_like': isLike,
        if (dislikeReason != null) 'dislike_reason': dislikeReason,
        'user_id': _auth.currentUser?.uid ?? 'unknown_user',
        'created_at': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('outfit_feedback').add(data);
      debugPrint("Outfit feedback saved to Firestore");
    } catch (e) {
      debugPrint("Failed to save outfit feedback: $e");
      throw Exception("Failed to save outfit feedback: $e");
    }
  }
}
