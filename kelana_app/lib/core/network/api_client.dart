import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/parsed_intent.dart';
import '../../models/place.dart';
import '../../models/itinerary.dart';

class ApiClient {
  late final Dio _dio;
  String _baseUrl = ApiConstants.defaultBaseUrl;

  ApiClient({String? customBaseUrl}) {
    _baseUrl = customBaseUrl ?? ApiConstants.defaultBaseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
    );
  }

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get(ApiConstants.health);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 1. Parse intent with Gemini via Backend Proxy
  Future<ParsedIntent> parseIntent(String query, {Map<String, dynamic>? preferences}) async {
    try {
      final response = await _dio.post(
        ApiConstants.parseIntent,
        data: {
          'query': query,
          if (preferences != null) 'preferences': preferences,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ParsedIntent.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Gagal memproses query.');
    } catch (e) {
      print('[ApiClient] Error in parseIntent: $e');
      rethrow;
    }
  }

  /// 2. Search places matching intent
  Future<List<Place>> searchPlaces(ParsedIntent intent) async {
    try {
      final response = await _dio.post(
        ApiConstants.searchPlaces,
        data: intent.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((item) => Place.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['error'] ?? 'Gagal mencari tempat.');
    } catch (e) {
      print('[ApiClient] Error in searchPlaces: $e');
      rethrow;
    }
  }

  /// 3. Build optimized itinerary
  Future<Itinerary> buildItinerary(List<Place> places, {ParsedIntent? intent}) async {
    try {
      final response = await _dio.post(
        ApiConstants.buildItinerary,
        data: {
          'places': places.map((p) => p.toJson()).toList(),
          if (intent != null) 'intent': intent.toJson(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        data['parsedIntent'] = intent?.toJson();
        return Itinerary.fromJson(data);
      }
      throw Exception(response.data['error'] ?? 'Gagal menyusun itinerary.');
    } catch (e) {
      print('[ApiClient] Error in buildItinerary: $e');
      rethrow;
    }
  }

  /// 4. Save Itinerary
  Future<Itinerary> saveItinerary(Itinerary itinerary) async {
    try {
      final response = await _dio.post(
        ApiConstants.itineraries,
        data: itinerary.toJson(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Itinerary.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return itinerary;
    } catch (e) {
      print('[ApiClient] Save itinerary failed, saving locally: $e');
      return itinerary;
    }
  }

  /// 5. Fetch Shared Itinerary
  Future<Itinerary?> getSharedItinerary(String shareCode) async {
    try {
      final response = await _dio.get('${ApiConstants.share}/$shareCode');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Itinerary.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
