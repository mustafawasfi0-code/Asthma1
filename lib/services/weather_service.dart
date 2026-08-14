import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/weather_status.dart';

class WeatherService {
  static Future<WeatherStatus> fetch({String? fallbackCity}) async {
    final device = await _resolveDeviceLocation();
    double? lat = device?.$1;
    double? lon = device?.$2;

    if (lat == null || lon == null) {
      if (fallbackCity != null && fallbackCity.trim().isNotEmpty) {
        final geocoded = await _geocodeCity(fallbackCity.trim());
        lat = geocoded?.$1;
        lon = geocoded?.$2;
      }
    }

    if (lat == null || lon == null) {
      return WeatherStatus(state: await _unresolvedLocationReason());
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return const WeatherStatus(state: WeatherState.unavailable);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      final temperature = (current?['temperature_2m'] as num?)?.toDouble();
      final code = (current?['weather_code'] as num?)?.toInt();
      if (temperature == null) {
        return const WeatherStatus(state: WeatherState.unavailable);
      }
      return WeatherStatus(
        state: WeatherState.ready,
        temperatureC: temperature,
        weatherCode: code,
        cityLabel: fallbackCity,
      );
    } on TimeoutException {
      return const WeatherStatus(state: WeatherState.noInternet);
    } on SocketException {
      return const WeatherStatus(state: WeatherState.noInternet);
    } catch (_) {
      return const WeatherStatus(state: WeatherState.unavailable);
    }
  }

  static Future<(double, double)?> _resolveDeviceLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherState> _unresolvedLocationReason() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return WeatherState.locationDenied;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return WeatherState.locationServiceDisabled;
      }
    } catch (_) {
      // Fall through to a generic unavailable state.
    }
    return WeatherState.unavailable;
  }

  static Future<(double, double)?> _geocodeCity(String city) async {
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeQueryComponent(city)}&count=1',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num?)?.toDouble();
      final lon = (first['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      return (lat, lon);
    } catch (_) {
      return null;
    }
  }
}
