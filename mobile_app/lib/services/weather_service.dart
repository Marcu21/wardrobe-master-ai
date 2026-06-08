import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String baseUrl =
      'https://api.openweathermap.org/data/2.5/forecast';

  // Singleton instance
  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() {
    return _instance;
  }

  WeatherService._internal();

  @visibleForTesting
  WeatherService.forTest();

  // Cache variables
  WeatherModel? _cachedWeather;
  DateTime? _lastFetchTime;

  WeatherModel? get cachedWeather => _cachedWeather;

  Future<String> getTripWeatherSummary(
    String destination,
    DateTime startDate,
    DateTime endDate,
  ) async {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    // Handle months spanning logic
    String monthString;
    if (startDate.month == endDate.month) {
      monthString = monthNames[startDate.month - 1];
    } else {
      monthString =
          "${monthNames[startDate.month - 1]}/${monthNames[endDate.month - 1]}";
    }

    final fallbackString =
        "Exact daily forecast unavailable. The trip takes place in $monthString. Please rely on your general knowledge to use typical historical weather averages and temperature ranges for this destination during this time of year to plan the daily outfits.";

    try {
      final daysUntilTrip = startDate.difference(DateTime.now()).inDays;

      // Historical Fallback (> 5 days) or past dates
      if (daysUntilTrip > 5 || daysUntilTrip < 0) {
        return fallbackString;
      }

      // Real Weather (<= 5 days)
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isEmpty) {
        return fallbackString;
      }

      final lat = locations.first.latitude;
      final lon = locations.first.longitude;

      final response = await http.get(
        Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> list = json['list'];

        if (list.isNotEmpty) {
          Map<String, Map<String, dynamic>> dailyWeather = {};

          for (var i = 0; i < list.length; i++) {
            final item = list[i];
            final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);

            final dateKey =
                "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
            final displayDate =
                "${monthNames[dt.month - 1].substring(0, 3)} ${dt.day}";

            DateTime forecastDateOnly = DateTime(dt.year, dt.month, dt.day);
            DateTime endDateOnly = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            );
            DateTime startDateOnly = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            );

            if (forecastDateOnly.isBefore(startDateOnly)) continue;
            if (forecastDateOnly.isAfter(endDateOnly)) break;

            int temp = (item['main']['temp'] as num).round();
            String condition = item['weather'][0]['main'];

            if (!dailyWeather.containsKey(dateKey)) {
              dailyWeather[dateKey] = {
                'displayDate': displayDate,
                'maxTemp': temp,
                'conditions': {condition: 1},
              };
            } else {
              if (temp > dailyWeather[dateKey]!['maxTemp']) {
                dailyWeather[dateKey]!['maxTemp'] = temp;
              }

              final conds =
                  dailyWeather[dateKey]!['conditions'] as Map<String, int>;
              conds[condition] = (conds[condition] ?? 0) + 1;
            }
          }

          if (dailyWeather.isEmpty) return fallbackString;

          List<String> dailySummaries = [];
          int dayCounter = 1;
          final sortedKeys = dailyWeather.keys.toList()..sort();

          for (String key in sortedKeys) {
            final dayData = dailyWeather[key]!;
            final displayDate = dayData['displayDate'];

            final conds = dayData['conditions'] as Map<String, int>;
            String dominantCondition = '';
            int maxCount = 0;
            conds.forEach((k, v) {
              if (v > maxCount) {
                maxCount = v;
                dominantCondition = k;
              }
            });

            final temp = dayData['maxTemp'];
            dailySummaries.add(
              "Day $dayCounter ($displayDate): $temp°C, $dominantCondition",
            );
            dayCounter++;
          }

          String finalSummary = "${dailySummaries.join(". ")}.";

          // Check for partial coverage
          final lastKey = sortedKeys.last;
          final lastDateParsed = DateTime.parse(lastKey);
          if (lastDateParsed.isBefore(
            DateTime(endDate.year, endDate.month, endDate.day),
          )) {
            finalSummary +=
                "\nNote: Exact forecast for the remaining days of the trip is unavailable. Please rely on your general knowledge of typical historical weather averages for this destination during this time of year to complete the wardrobe selection.";
          }

          return finalSummary;
        }
      }

      return fallbackString;
    } catch (e) {
      print('Error getting trip weather summary: $e');
      return fallbackString;
    }
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
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
    // Check Cache validity (30 minutes)
    if (_cachedWeather != null && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inMinutes < 30) {
        return _cachedWeather!;
      }
    }

    // Get accurate city name using Geocoding
    String cityName = 'Unknown Location';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        cityName =
            placemarks.first.locality ??
            placemarks.first.subLocality ??
            'Unknown Location';
      }
    } catch (e) {
      print('Error fetching city name: $e');
    }

    // Fetch Forecast Data
    final response = await http.get(
      Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> list = json['list'];

      if (list.isNotEmpty) {
        // Current weather is effectively the first item
        final current = list.first;

        // Base time: Current hour rounded down
        final now = DateTime.now();
        final baseTime = DateTime(now.year, now.month, now.day, now.hour);

        // Label is forced to the local rounded hour; icon suffix is re-derived from
        // baseTime because the API slot's UTC time can be up to 3h ahead of our label.
        final currentItem = ForecastItem(
          time: baseTime,
          timeLabel: "${baseTime.hour.toString().padLeft(2, '0')}:00",
          temperature: (current['main']['temp'] as num).round(),
          condition: current['weather'][0]['main'],
          iconCode: _alignIconWithLocalTime(
            current['weather'][0]['icon'],
            baseTime,
          ),
        );

        // Get next 8 items for 24h forecast (3h intervals * 8 = 24h)
        final List<ForecastItem> forecastList = [];
        // Add current item first
        forecastList.add(currentItem);

        // Process next 8 items
        final apiForecast = list.skip(1).take(8).toList();

        for (int i = 0; i < apiForecast.length; i++) {
          final itemJson = apiForecast[i];
          // Calculate projected time
          final projectedTime = baseTime.add(Duration(hours: (i + 1) * 3));
          final timeLabel =
              "${projectedTime.hour.toString().padLeft(2, '0')}:00";

          forecastList.add(
            ForecastItem(
              time:
                  projectedTime,
              timeLabel: timeLabel,
              temperature: (itemJson['main']['temp'] as num).round(),
              condition: itemJson['weather'][0]['main'],
              iconCode: _alignIconWithLocalTime(
                itemJson['weather'][0]['icon'],
                projectedTime,
              ),
            ),
          );
        }

        final weatherModel = WeatherModel(
          cityName: cityName,
          temperature: (current['main']['temp'] as num).round(),
          condition: current['weather'][0]['main'],
          description: current['weather'][0]['description'],
          iconCode: _alignIconWithLocalTime(
            current['weather'][0]['icon'],
            baseTime,
          ),
          forecast: forecastList,
        );

        // Update Cache
        _cachedWeather = weatherModel;
        _lastFetchTime = DateTime.now();

        return weatherModel;
      } else {
        throw Exception('No weather data available');
      }
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  // OpenWeather icon suffix ('d'/'n') is re-derived from local time because
  // fetchWeather() shifts slots up to 3h. Night = 20:00–05:59 local.
  String _alignIconWithLocalTime(String apiIcon, DateTime localTime) {
    if (apiIcon.length < 2) return apiIcon;
    final h = localTime.hour;
    final isNight = h < 6 || h >= 20;
    final base = apiIcon.substring(0, apiIcon.length - 1);
    return '$base${isNight ? 'n' : 'd'}';
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
  final String timeLabel; // Pre-formatted display string
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
