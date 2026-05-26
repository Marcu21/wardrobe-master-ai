import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> saveTrip({
    required String name,
    required String destination,
    required List<String> itemIds,
    required List<Map<String, dynamic>> outfits,
    required String reasoning,
    required String vibe,
    String? tripPlans,
    String? luggageSize,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = {
        'name': name,
        'destination': destination,
        'item_ids': itemIds,
        'outfits': outfits,
        'reasoning': reasoning,
        'vibe': vibe,
        if (tripPlans != null) 'trip_plans': tripPlans,
        if (luggageSize != null) 'luggage_size': luggageSize,
        if (startDate != null) 'start_date': Timestamp.fromDate(startDate),
        if (endDate != null) 'end_date': Timestamp.fromDate(endDate),
        'created_at': FieldValue.serverTimestamp(),
        'user_id': _auth.currentUser?.uid ?? 'unknown_user',
      };
      final docRef = await _firestore.collection('trips').add(data);
      debugPrint("Trip saved to Firestore: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint("Failed to save trip: $e");
      throw Exception("Failed to save trip: $e");
    }
  }

  Future<void> updateTrip(
    String tripId,
    List<String> itemIds,
    List<Map<String, dynamic>> outfits,
    String reasoning, {
    String? vibe,
    String? tripPlans,
    String? luggageSize,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'item_ids': itemIds,
        'outfits': outfits,
        'reasoning': reasoning,
      };
      if (vibe != null) updates['vibe'] = vibe;
      if (tripPlans != null) updates['trip_plans'] = tripPlans;
      if (luggageSize != null) updates['luggage_size'] = luggageSize;
      if (startDate != null) updates['start_date'] = Timestamp.fromDate(startDate);
      if (endDate != null) updates['end_date'] = Timestamp.fromDate(endDate);
      await _firestore.collection('trips').doc(tripId).update(updates);
      debugPrint("Trip updated: $tripId");
    } catch (e) {
      debugPrint("Failed to update trip: $e");
      throw Exception("Failed to update trip: $e");
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).delete();
      debugPrint("Trip deleted: $tripId");
    } catch (e) {
      debugPrint("Failed to delete trip: $e");
      throw Exception("Failed to delete trip: $e");
    }
  }
}
