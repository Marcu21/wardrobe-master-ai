import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_app/services/firebase_service.dart';

class TripOutfit {
  final String title;
  final String description;
  final List<String> itemIds;

  TripOutfit({
    required this.title,
    required this.description,
    required this.itemIds,
  });

  factory TripOutfit.fromJson(Map<String, dynamic> json) {
    return TripOutfit(
      title: json['title'] as String? ?? 'Unnamed Outfit',
      description: json['description'] as String? ?? '',
      itemIds: List<String>.from(json['item_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'item_ids': itemIds};
  }
}

class CapsuleWardrobe {
  final List<String> selectedItemIds;
  final String reasoning;
  final String? warningMessage;
  final List<TripOutfit> outfits;

  CapsuleWardrobe({
    required this.selectedItemIds,
    required this.reasoning,
    this.warningMessage,
    required this.outfits,
  });

  factory CapsuleWardrobe.fromJson(Map<String, dynamic> json) {
    var outfitsList = json['outfits'] as List? ?? [];
    List<TripOutfit> parsedOutfits = outfitsList
        .map(
          (outfitJson) =>
              TripOutfit.fromJson(outfitJson as Map<String, dynamic>),
        )
        .toList();

    return CapsuleWardrobe(
      selectedItemIds: List<String>.from(json['selected_item_ids'] ?? []),
      reasoning: json['reasoning'] as String? ?? '',
      warningMessage: json['warning_message'] as String?,
      outfits: parsedOutfits,
    );
  }
}

class PackingService {
  final String baseUrl;

  PackingService({String? baseUrl})
    : baseUrl = baseUrl ?? dotenv.env['SERVER_URL'] ?? 'http://10.0.2.2:8000';

  Future<CapsuleWardrobe> generatePackingList({
    required String destination,
    required int days,
    required String vibe,
    required String weatherForecast,
    String? wardrobeId,
    List<String>? itemIdsOverride,
    String? tripPlans,
    String? luggageSize,
  }) async {
    final uri = Uri.parse('$baseUrl/generate-packing/');
    final token = await FirebaseService().currentUser?.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'destination': destination,
              'days': days,
              'vibe': vibe,
              'weather_forecast': weatherForecast,
              if (wardrobeId != null) 'wardrobe_id': wardrobeId,
              if (itemIdsOverride != null) 'item_ids_override': itemIdsOverride,
              if (tripPlans != null) 'trip_plans': tripPlans,
              if (luggageSize != null) 'luggage_size': luggageSize,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return CapsuleWardrobe.fromJson(decoded);
      } else {
        throw Exception(
          'Failed to generate packing list: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Packing list generation is taking too long. Please check your connection and try again.',
      );
    } catch (e) {
      print('Network error generating packing list: $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<TripOutfit> generateSpecificTripOutfit({
    required String destination,
    required String vibe,
    required String weatherForecast,
    required List<String> suitcaseItemIds,
    required String userContext,
    List<Map<String, dynamic>>? existingOutfits,
    String? feedback,
    List<String>? currentOutfitItemIds,
  }) async {
    final uri = Uri.parse('$baseUrl/generate-trip-outfit/');
    final token = await FirebaseService().currentUser?.getIdToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'destination': destination,
              'vibe': vibe,
              'weather_forecast': weatherForecast,
              'suitcase_item_ids': suitcaseItemIds,
              'user_context': userContext,
              if (existingOutfits != null) 'existing_outfits': existingOutfits,
              if (feedback != null) 'feedback': feedback,
              if (currentOutfitItemIds != null)
                'current_outfit_item_ids': currentOutfitItemIds,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return TripOutfit.fromJson(decoded);
      } else {
        throw Exception(
          'Failed to generate trip outfit: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Outfit generation is taking too long. Please check your connection and try again.',
      );
    } catch (e) {
      print('Network error generating trip outfit: $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
