import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/clothing_repository.dart';
import 'package:mobile_app/services/outfit_repository.dart';
import 'package:mobile_app/services/user_settings_service.dart';
import 'package:mobile_app/services/weather_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'chat_message.dart';

class AiStylistViewModel extends ChangeNotifier {
  // Singleton — chat history survives navigation pops
  static final AiStylistViewModel shared = AiStylistViewModel._();

  final ApiService _apiService;
  final ClothingRepository _clothingRepository;
  final OutfitRepository _outfitRepository;
  final WeatherService _weatherService;

  final List<ChatMessage> _messages = [];
  final TextEditingController controller = TextEditingController();
  bool _isTyping = false;
  bool _disposed = false;

  @visibleForTesting
  final String? Function()? wardrobeIdProvider;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  OutfitRepository get outfitRepository => _outfitRepository;

  AiStylistViewModel._()
      : _apiService = ApiService(),
        _clothingRepository = ClothingRepository(),
        _outfitRepository = OutfitRepository(),
        _weatherService = WeatherService(),
        wardrobeIdProvider = null;

  static String? _nullWardrobeId() => null;

  @visibleForTesting
  AiStylistViewModel.forTest({
    ApiService? apiService,
    WeatherService? weatherService,
  })  : _apiService = apiService ?? ApiService.forTest(),
        _clothingRepository = ClothingRepository(),
        _outfitRepository = OutfitRepository(),
        _weatherService = weatherService ?? WeatherService.forTest(),
        wardrobeIdProvider = _nullWardrobeId;

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }

  // Triggers a rebuild when a ChatMessage is mutated in-place.
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
      final prioritizeNeglected =
          await UserSettingsService().getPrioritizeNeglected();
      final response = await _apiService.generateOutfit(
        userPrompt: text,
        currentWeather: currentWeatherStr,
        hourlyForecast: hourlyForecastStr,
        wardrobeId: wardrobeIdProvider != null
            ? wardrobeIdProvider!()
            : wardrobeStateService.activeWardrobeId,
        prioritizeNeglected: prioritizeNeglected,
      );

      final explanation = response['explanation'] as String;
      final selectedIds =
          List<String>.from(response['selected_item_ids'] ?? []);
      final overallScore = response['overall_score'] as int?;
      final scores = response['scores'] as Map<String, dynamic>?;

      List<Map<String, dynamic>> outfitItems = [];
      if (selectedIds.isNotEmpty) {
        outfitItems = await _clothingRepository.getItemsByIds(selectedIds);
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
