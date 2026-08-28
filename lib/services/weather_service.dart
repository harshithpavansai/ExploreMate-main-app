import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';


/// Represents a snapshot of current weather conditions.
class WeatherModel {
  final double temperature;   // °C
  final double windSpeed;     // km/h
  final int weatherCode;      // WMO weather code
  final String condition;     // human-readable label
  final String icon;          // emoji icon

  const WeatherModel({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.condition,
    required this.icon,
  });

  factory WeatherModel.fromOpenMeteo(Map<String, dynamic> map) {
    final code = (map['weathercode'] as num?)?.toInt() ?? 0;
    return WeatherModel(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (map['windspeed'] as num?)?.toDouble() ?? 0.0,
      weatherCode: code,
      condition: _codeToCondition(code),
      icon: _codeToIcon(code),
    );
  }

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'condition': condition,
        'icon': icon,
      };

  factory WeatherModel.fromMap(Map<String, dynamic> map) {
    return WeatherModel(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (map['windSpeed'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (map['weatherCode'] as num?)?.toInt() ?? 0,
      condition: map['condition'] as String? ?? 'Clear',
      icon: map['icon'] as String? ?? '☀️',
    );
  }

  // ── WMO code helpers ──────────────────────────────────────────────────────
  static String _codeToCondition(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  static String _codeToIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }

  @override
  String toString() => 'WeatherModel($icon $temperature°C, $condition)';
}



/// Weather service using Open-Meteo API via the Node.js backend.
/// Open-Meteo is completely free — no API key required.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  /// Fetch current weather for [lat]/[lon]. Defaults to Visakhapatnam.
  Future<WeatherModel?> getCurrentWeather({
    double lat = 17.6868,
    double lon = 83.2185,
  }) async {
    // Try local backend, then Render, then direct Open-Meteo
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http
            .get(ApiConfig.getUri('/weather?lat=$lat&lng=$lon'))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['weather'] as Map<String, dynamic>?;
          if (data != null) return WeatherModel.fromOpenMeteo(data);
        }
      } catch (e) {
        debugPrint('WeatherService failed — $e');
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    // Direct Open-Meteo fallback — always free, no backend needed
    return _directFetch(lat: lat, lon: lon);
  }

  /// Directly query Open-Meteo if the backend is unreachable.
  Future<WeatherModel?> _directFetch({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lon&current_weather=true');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['current_weather']
            as Map<String, dynamic>?;
        if (data != null) return WeatherModel.fromOpenMeteo(data);
      }
    } catch (e) {
      debugPrint('WeatherService._directFetch error: $e');
    }
    return null;
  }
}
