import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
}

class CapsuleWardrobe {
  final List<String> selectedItemIds;
  final String reasoning;
  final List<TripOutfit> outfits;

  CapsuleWardrobe({
    required this.selectedItemIds,
    required this.reasoning,
    required this.outfits,
  });

  factory CapsuleWardrobe.fromJson(Map<String, dynamic> json) {
    var outfitsList = json['outfits'] as List? ?? [];
    List<TripOutfit> parsedOutfits = outfitsList
        .map((outfitJson) => TripOutfit.fromJson(outfitJson as Map<String, dynamic>))
        .toList();

    return CapsuleWardrobe(
      selectedItemIds: List<String>.from(json['selected_item_ids'] ?? []),
      reasoning: json['reasoning'] as String? ?? '',
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
  }) async {
    final uri = Uri.parse('$baseUrl/generate-packing/');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'destination': destination,
          'days': days,
          'vibe': vibe,
          'weather_forecast': weatherForecast,
          'user_id': 'test_user',
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return CapsuleWardrobe.fromJson(decoded);
      } else {
        throw Exception('Failed to generate packing list: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network error generating packing list: $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
