import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Default URL depends on platform:
  // - Android emulator uses 10.0.2.2 to access host machine's localhost
  // - iOS / Web / Desktop uses localhost
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  // Endpoints
  static const String health = '/health';
  static const String parseIntent = '/parse-intent';
  static const String searchPlaces = '/search-places';
  static const String buildItinerary = '/build-itinerary';
  static const String itineraries = '/itineraries';
  static const String share = '/share';
}
