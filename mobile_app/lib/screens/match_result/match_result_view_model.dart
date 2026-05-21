import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:http/http.dart' as http;

class MatchResultViewModel extends ChangeNotifier {
  bool isLoading = true;
  int matchScore = 0;
  List<String> pros = [];
  List<String> cons = [];
  List<Map<String, dynamic>> generatedOutfits = [];
  String? errorMessage;

  bool _disposed = false;

  MatchResultViewModel({required Map<String, dynamic> scannedItemData}) {
    _calculateScoreAndOutfits(scannedItemData);
  }

  Future<void> _calculateScoreAndOutfits(
    Map<String, dynamic> scannedItemData,
  ) async {
    try {
      final scannedMetadata =
          scannedItemData['metadata'] as Map<String, dynamic>? ?? {};
      final scannedBasicInfo =
          scannedMetadata['basic_info'] as Map<String, dynamic>? ?? {};
      final scannedStylingInfo =
          scannedMetadata['styling_info'] as Map<String, dynamic>? ?? {};

      final scannedItemPayload = {
        "item_id": "scanned_new_item",
        "category": scannedBasicInfo['category']?.toString() ?? '',
        "sub_category": scannedBasicInfo['sub_category']?.toString() ?? '',
        "primary_colors": List<String>.from(
          scannedBasicInfo['primary_colors'] ?? [],
        ),
        "style_occasions": List<String>.from(
          scannedStylingInfo['style_occasions'] ?? [],
        ),
        "seasonality": List<String>.from(
          scannedStylingInfo['seasonality'] ?? [],
        ),
      };

      final snapshot = await FirebaseFirestore.instance
          .collection('clothing')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      final wardrobeDocs = snapshot.docs;
      final List<Map<String, dynamic>> wardrobePayload = [];
      final Map<String, Map<String, dynamic>> wardrobeMap = {};

      for (var doc in wardrobeDocs) {
        final data = doc.data();
        wardrobeMap[doc.id] = data;

        final itemBasic = data['basic_info'] as Map<String, dynamic>? ?? {};
        final itemStyling =
            data['styling_info'] as Map<String, dynamic>? ?? {};

        wardrobePayload.add({
          "item_id": doc.id,
          "category": itemBasic['category']?.toString() ?? '',
          "sub_category": itemBasic['sub_category']?.toString() ?? '',
          "primary_colors": List<String>.from(
            itemBasic['primary_colors'] ?? [],
          ),
          "style_occasions": List<String>.from(
            itemStyling['style_occasions'] ?? [],
          ),
          "seasonality": List<String>.from(
            itemStyling['seasonality'] ?? [],
          ),
        });
      }

      final apiService = ApiService();
      final uri = Uri.parse('${apiService.baseUrl}/generate-outfits/');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "scanned_item": scannedItemPayload,
          "wardrobe": wardrobePayload,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to generate outfits: ${response.statusCode} - ${response.body}",
        );
      }

      final responseBody = jsonDecode(response.body);

      final scoreVal = responseBody['score'] ?? 0;
      final prosList = List<String>.from(responseBody['pros'] ?? []);
      final consList = List<String>.from(responseBody['cons'] ?? []);
      final outfitsList = List<dynamic>.from(responseBody['outfits'] ?? []);

      final List<Map<String, dynamic>> finalOutfits = [];
      for (var outfit in outfitsList) {
        final outfitName = outfit['outfit_name'] ?? 'Outfit';
        final stylingNotes = outfit['styling_notes'] ?? '';
        final itemIds = List<String>.from(outfit['item_ids'] ?? []);

        final List<Map<String, dynamic>> resolvedItems = [];
        for (var id in itemIds) {
          if (id == 'scanned_new_item') {
            resolvedItems.add(scannedItemData);
          } else if (wardrobeMap.containsKey(id)) {
            resolvedItems.add(wardrobeMap[id]!);
          }
        }

        if (resolvedItems.isNotEmpty) {
          finalOutfits.add({
            "outfit_name": outfitName,
            "styling_notes": stylingNotes,
            "items": resolvedItems,
          });
        }
      }

      if (!_disposed) {
        matchScore = (scoreVal as num).toInt();
        pros = prosList;
        cons = consList;
        generatedOutfits = finalOutfits;
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
