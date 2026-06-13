import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get _serverUrl =>
      dotenv.env['SERVER_URL'] ?? 'http://10.0.2.2:8000';

  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() => _instance;

  WeatherService._internal();

  @visibleForTesting
  WeatherService.forTest();

  WeatherModel? _cachedWeather;
  DateTime? _lastFetchTime;

  WeatherModel? get cachedWeather => _cachedWeather;

  Future<String> getTripWeatherSummary(
    String destination,
    DateTime startDate,
    DateTime endDate,
  ) async {
    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];

    final monthString = startDate.month == endDate.month
        ? monthNames[startDate.month - 1]
        : "${monthNames[startDate.month - 1]}/${monthNames[endDate.month - 1]}";

    final fallback =
        "Exact daily forecast unavailable. The trip takes place in $monthString. "
        "Please rely on your general knowledge to use typical historical weather averages "
        "and temperature ranges for this destination during this time of year to plan the daily outfits.";

    try {
      final uri = Uri.parse('$_serverUrl/weather/trip-summary').replace(
        queryParameters: {
          'destination': destination,
          'start_date':
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
          'end_date':
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        },
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['summary'] as String? ?? fallback;
      }
    } catch (e) {
      print('Error getting trip weather summary: $e');
    }
    return fallback;
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<WeatherModel> fetchWeather(double lat, double lon) async {
    if (_cachedWeather != null && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inMinutes < 30) {
        return _cachedWeather!;
      }
    }

    final response = await http
        .get(Uri.parse('$_serverUrl/weather/current?lat=$lat&lon=$lon'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      final forecastList = (json['forecast'] as List<dynamic>).map((item) {
        final ms = item['time_ms'] as int;
        return ForecastItem(
          time: DateTime.fromMillisecondsSinceEpoch(ms),
          timeLabel: item['time_label'] as String,
          temperature: item['temperature'] as int,
          condition: item['condition'] as String,
          iconCode: item['icon_code'] as String,
        );
      }).toList();

      final weatherModel = WeatherModel(
        cityName: json['city_name'] as String,
        temperature: json['temperature'] as int,
        condition: json['condition'] as String,
        description: json['description'] as String,
        iconCode: json['icon_code'] as String,
        forecast: forecastList,
      );

      _cachedWeather = weatherModel;
      _lastFetchTime = DateTime.now();
      return weatherModel;
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
}

class WeatherModel {
  final String cityName;
  final int temperature;
  final String condition;
  final String description;
  final String iconCode;
  final List<ForecastItem> forecast;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.forecast,
  });
}

class ForecastItem {
  final DateTime time;
  final String timeLabel;
  final int temperature;
  final String condition;
  final String iconCode;

  ForecastItem({
    required this.time,
    required this.timeLabel,
    required this.temperature,
    required this.condition,
    required this.iconCode,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    final dt = DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000);
    return ForecastItem(
      time: dt,
      timeLabel: "${dt.hour.toString().padLeft(2, '0')}:00",
      temperature: (json['main']['temp'] as num).round(),
      condition: json['weather'][0]['main'],
      iconCode: json['weather'][0]['icon'],
    );
  }
}
