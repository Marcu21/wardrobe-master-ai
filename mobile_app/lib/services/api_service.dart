import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_app/services/auth_service.dart';

class ApiService {
  final String baseUrl;

  // Use a default URL, but allow it to be overridden for flexibility (e.g. from environment or config)
  // 10.0.2.2 is the localhost alias for Android emulator
  // For physical devices, use your computer's local IP address (e.g. 192.168.x.x)
  ApiService({String? baseUrl})
    : baseUrl = baseUrl ?? dotenv.env['SERVER_URL'] ?? 'http://10.0.2.2:8000';

  Future<Map<String, dynamic>?> processItem(
    File itemFile, {
    File? tagFile,
  }) async {
    var uri = Uri.parse('$baseUrl/process-item/');
    var request = http.MultipartRequest('POST', uri);

    // Add itemFile (mandatory)
    // We can try to guess mime type or just use standard image/*
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        itemFile.path,
        contentType: MediaType('image', 'jpeg'), // Adjust if needed, or detect
      ),
    );

    // Add tagFile (optional)
    if (tagFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'tag_file',
          tagFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('processItem'),
      );
      var response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('processItem'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to process item: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Analysis is taking too long. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<Map<String, dynamic>> generateOutfit({
    required String userPrompt,
    required String currentWeather,
    required String hourlyForecast,
    String? wardrobeId,
  }) async {
    final uri = Uri.parse('$baseUrl/generate-outfit/');
    final token = await AuthService().currentUser?.getIdToken();
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
              'user_prompt': userPrompt,
              'current_weather': currentWeather,
              'hourly_forecast': hourlyForecast,
              if (wardrobeId != null) 'wardrobe_id': wardrobeId,
            }),
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw TimeoutException('generateOutfit'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to generate outfit: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Outfit generation is taking too long. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
