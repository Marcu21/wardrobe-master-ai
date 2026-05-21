import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/services/weather_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'chat_message.dart';

class AiStylistViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final FirebaseService _firebaseService;
  final WeatherService _weatherService;

  final List<ChatMessage> _messages = [];
  final TextEditingController controller = TextEditingController();
  bool _isTyping = false;
  bool _disposed = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  /// Exposed so OutfitMessageCard can call Firebase directly.
  FirebaseService get firebaseService => _firebaseService;

  AiStylistViewModel()
      : _apiService = ApiService(),
        _firebaseService = FirebaseService(),
        _weatherService = WeatherService();

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }

  /// Called by child widgets that mutate ChatMessage fields in-place.
  /// Triggers a screen rebuild without altering the messages list.
  void notifyUpdate() => _notify();

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messages.add(ChatMessage(role: 'user', text: text));
    _isTyping = true;
    controller.clear();
    _notify();

    String currentWeatherStr = 'Unknown Weather';
    String hourlyForecastStr = 'Unknown Forecast';
    final weather = _weatherService.cachedWeather;
    if (weather != null) {
      currentWeatherStr =
          'Currently ${weather.temperature}°C and ${weather.condition} in ${weather.cityName}';
      final buffer = StringBuffer();
      for (final item in weather.forecast) {
        buffer
            .write('${item.timeLabel}: ${item.temperature}°C (${item.condition}), ');
      }
      hourlyForecastStr = buffer.toString();
    }

    try {
      final response = await _apiService.generateOutfit(
        userPrompt: text,
        currentWeather: currentWeatherStr,
        hourlyForecast: hourlyForecastStr,
        wardrobeId: wardrobeStateService.activeWardrobeId,
      );

      final explanation = response['explanation'] as String;
      final selectedIds =
          List<String>.from(response['selected_item_ids'] ?? []);
      final overallScore = response['overall_score'] as int?;
      final scores = response['scores'] as Map<String, dynamic>?;

      List<Map<String, dynamic>> outfitItems = [];
      if (selectedIds.isNotEmpty) {
        outfitItems = await _firebaseService.getItemsByIds(selectedIds);
      }

      _isTyping = false;
      if (outfitItems.isNotEmpty) {
        _messages.add(
          ChatMessage(
            role: 'ai',
            text: explanation,
            isOutfit: true,
            outfitItems: outfitItems,
            overallScore: overallScore,
            scores: scores,
            userPrompt: text,
            weatherContext: '$currentWeatherStr | Forecast: $hourlyForecastStr',
          ),
        );
      } else {
        _messages.add(ChatMessage(role: 'ai', text: explanation));
      }
      _notify();
    } catch (_) {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          role: 'ai',
          text:
              "Sorry, I'm having trouble connecting to my fashion brain right now. Please try again later.",
        ),
      );
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
