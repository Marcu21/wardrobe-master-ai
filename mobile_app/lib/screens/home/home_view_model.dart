import 'package:flutter/material.dart';
import '../../services/weather_service.dart';

class HomeViewModel extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherModel? weather;
  bool isLoading = true;
  String? error;

  HomeViewModel({WeatherService? weatherService})
      : _weatherService = weatherService ?? WeatherService() {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final position = await _weatherService.determinePosition();
      weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
