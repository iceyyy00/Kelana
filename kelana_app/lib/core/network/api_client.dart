import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/api_constants.dart';
import '../../models/parsed_intent.dart';
import '../../models/place.dart';
import '../../models/itinerary.dart';

class ApiClient {
  static const _retryCountKey = 'apiClientConnectionTimeoutRetryCount';
  static const _maxConnectionTimeoutRetries = 3;
  static const Map<String, String> _chitChatRules = {
    'halo': 'Hai! Mau merencanakan perjalanan ke mana kita hari ini? ✈️',
    'hi': 'Halo! Ada rencana liburan seru hari ini? Mau ke mana?',
    'hai': 'Hai juga! Siap berpetualang? Kamu mau pergi ke mana hari ini?',
    'p': 'Halo! Ada yang bisa dibantu untuk rencana perjalananmu hari ini?',
    'terima kasih':
        'Sama-sama! Semoga rencana perjalananmu menyenangkan. Ada kota lain yang ingin kamu kunjungi?',
    'makasih': 'Sama-sama! Selamat merencanakan liburanmu ya!',
  };
  static const _incompleteQueryResponse =
      'Halo! Hari ini kita mau merencanakan liburan ke mana nih? Yuk, beri tahu '
      'aku kota atau destinasi tujuanmu!';

  late final Dio _dio;
  String _baseUrl = ApiConstants.defaultBaseUrl;

  ApiClient({String? customBaseUrl}) {
    _baseUrl = _normalizeBaseUrl(customBaseUrl ?? ApiConstants.defaultBaseUrl);
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await FirebaseAuth.instance.currentUser?.getIdToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
              ),
            );
          }
        },
        onError: (error, handler) async {
          if (error.type != DioExceptionType.connectionTimeout) {
            handler.next(error);
            return;
          }

          final retryCount =
              error.requestOptions.extra[_retryCountKey] as int? ?? 0;
          if (retryCount >= _maxConnectionTimeoutRetries) {
            handler.next(error);
            return;
          }

          final nextRetry = retryCount + 1;
          print(
            '[ApiClient] Connection timeout. Retrying '
            '($nextRetry/$_maxConnectionTimeoutRetries)...',
          );
          await Future.delayed(const Duration(seconds: 2));
          error.requestOptions.extra[_retryCountKey] = nextRetry;

          try {
            final response = await _dio.fetch<dynamic>(error.requestOptions);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );

    // Logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
    );
  }

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = _normalizeBaseUrl(newUrl);
    _dio.options.baseUrl = _baseUrl;
  }

  String _normalizeBaseUrl(String value) {
    final uri = Uri.parse(value.trim());
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/api')) {
      path = path.substring(0, path.length - '/api'.length);
    }
    final normalizedPath = path.isEmpty ? '/' : '$path/';
    return uri.replace(path: normalizedPath).toString();
  }

  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get(ApiConstants.health);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String? handleLocalChitChat(String query) {
    return _chitChatRules[query.trim().toLowerCase()];
  }

  /// 1. Parse intent with Gemini via Backend Proxy
  Future<ParsedIntent> parseIntent(String query,
      {Map<String, dynamic>? preferences,
      List<Map<String, String>> history = const []}) async {
    if (history.isEmpty && _isIncompleteQuery(query)) {
      return ParsedIntent(
        location: '',
        budget: 0,
        budgetLevel: 'unspecified',
        foodBudgetPercent: 0,
        accommodationBudgetPercent: 0,
        categories: const [],
        dateTime: 'Belum ditentukan',
        peopleCount: 0,
        userNotes: _incompleteQueryResponse,
        chatResponse: _incompleteQueryResponse,
      );
    }

    try {
      final response = await _dio.post(
        ApiConstants.parseIntent,
        data: {
          'query': query,
          if (preferences != null) 'preferences': preferences,
          'history': history
              .map((message) => {
                    'role': message['role'],
                    'parts': [
                      {'text': message['text']},
                    ],
                  })
              .toList(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ParsedIntent.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Gagal memproses query.');
    } catch (e) {
      print('[ApiClient] Error in parseIntent: $e');
      rethrow;
    }
  }

  bool _isIncompleteQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    const greetings = {'halo', 'hai', 'hi', 'hello', 'hey'};
    return normalizedQuery.length < 5 || greetings.contains(normalizedQuery);
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
        return list
            .map((item) => Place.fromJson(
                Map<String, dynamic>.from(item as Map<String, dynamic>)))
            .toList();
      }
      throw Exception(response.data['error'] ?? 'Gagal mencari tempat.');
    } catch (e) {
      print('[ApiClient] Error in searchPlaces: $e');
      rethrow;
    }
  }

  /// 3. Build optimized itinerary
  Future<Itinerary> buildItinerary(List<Place> places,
      {ParsedIntent? intent}) async {
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
        return Itinerary.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['error'] ?? 'Gagal menyimpan itinerary.');
    } catch (e) {
      print('[ApiClient] Save itinerary failed, saving locally: $e');
      return itinerary;
    }
  }

  Future<List<Itinerary>> getItineraries() async {
    final response = await _dio.get(ApiConstants.itineraries);
    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => Itinerary.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(response.data['error'] ?? 'Gagal memuat itinerary.');
  }

  Future<void> deleteItinerary(String id) async {
    final response = await _dio.delete(
      '${ApiConstants.itineraries}/${Uri.encodeComponent(id)}',
    );
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['error'] ?? 'Gagal menghapus itinerary.');
    }
  }

  /// 5. Fetch Shared Itinerary
  Future<Itinerary?> getSharedItinerary(String shareCode) async {
    try {
      final response = await _dio.get('${ApiConstants.share}/$shareCode');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Itinerary.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
