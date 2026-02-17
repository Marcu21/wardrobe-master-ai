import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = '63533a54944c5287300c8b61ce227039';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  // Singleton instance
  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() {
    return _instance;
  }

  WeatherService._internal();

  // Cache variables
  WeatherModel? _cachedWeather;
  DateTime? _lastFetchTime;

  WeatherModel? get cachedWeather => _cachedWeather;

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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
        'Location permissions are permanently denied, we cannot request permissions.');
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

    // 1. Get accurate city name using Geocoding
    String cityName = 'Unknown Location';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        cityName = placemarks.first.locality ?? placemarks.first.subLocality ?? 'Unknown Location';
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching city name: $e');
    }

    // 2. Fetch Forecast Data
    final response = await http.get(Uri.parse(
        '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> list = json['list'];

      if (list.isNotEmpty) {
        // Current weather is effectively the first item (or close to it)
        final current = list.first;
        
        // Base time: Current hour rounded down (e.g. 19:13 -> 19:00)
        final now = DateTime.now();
        final baseTime = DateTime(now.year, now.month, now.day, now.hour);

        // Current item (Now)
        // We manually force the time label to be the current rounded hour (e.g. "19:00")
        final currentItem = ForecastItem(
          time: baseTime,
          timeLabel: "${baseTime.hour.toString().padLeft(2, '0')}:00",
          temperature: (current['main']['temp'] as num).round(),
          condition: current['weather'][0]['main'],
          iconCode: current['weather'][0]['icon'],
        );
        
        // Get next 8 items for 24h forecast (3h intervals * 8 = 24h)
        // We skip the first one as it's "current"
        final List<ForecastItem> forecastList = [];
        // Add current item first
        forecastList.add(currentItem);

        // Process next 8 items
        final apiForecast = list.skip(1).take(8).toList();
        
        for (int i = 0; i < apiForecast.length; i++) {
          final itemJson = apiForecast[i];
          // Calculate projected time: baseTime + (i+1)*3 hours
          final projectedTime = baseTime.add(Duration(hours: (i + 1) * 3));
          final timeLabel = "${projectedTime.hour.toString().padLeft(2, '0')}:00";
          
          forecastList.add(ForecastItem(
            time: projectedTime, // We purposely override the API time with our calculated time
            timeLabel: timeLabel,
            temperature: (itemJson['main']['temp'] as num).round(),
            condition: itemJson['weather'][0]['main'],
            iconCode: itemJson['weather'][0]['icon'],
          ));
        }

        final weatherModel = WeatherModel(
          cityName: cityName,
          temperature: (current['main']['temp'] as num).round(),
          condition: current['weather'][0]['main'],
          description: current['weather'][0]['description'],
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
}

class WeatherModel {
  final String cityName;
  final int temperature;
  final String condition;
  final String description;
  final List<ForecastItem> forecast;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.forecast,
  });
}

class ForecastItem {
  final DateTime time;
  final String timeLabel; // Pre-formatted display string (e.g. "19:00")
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
    // Note: This factory is less used now since we manually construct items in fetchWeather
    // but kept for compatibility or fallback.
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
