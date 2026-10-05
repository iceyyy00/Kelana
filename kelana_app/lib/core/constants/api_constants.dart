import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'KELANA_API_BASE_URL',
    defaultValue:
        'https://asia-southeast1-kelana-f39b1.cloudfunctions.net/backend',
  );

  // Default URL depends on platform:
  // - Android emulator uses 10.0.2.2 to access host machine's localhost
  // - iOS / Web / Desktop uses localhost
  static String get defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://localhost:5000/';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/';
    } catch (_) {}
    return 'http://localhost:5000/';
  }

  // Endpoints
  static const String health = 'api/health';
  static const String parseIntent = 'api/parse-intent';
  static const String searchPlaces = 'api/search-places';
  static const String buildItinerary = 'api/build-itinerary';
  static const String itineraries = 'api/itineraries';
  static const String share = 'api/share';
}
