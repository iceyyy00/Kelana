import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/parsed_intent.dart';
import '../models/place.dart';
import '../models/itinerary.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class TripCreationState {
  final bool isLoading;
  final String? loadingMessage;
  final String? errorMessage;
  final String rawQuery;
  final ParsedIntent? parsedIntent;
  final List<Place> recommendedPlaces;
  final List<Place> selectedPlaces;
  final Itinerary? builtItinerary;

  TripCreationState({
    this.isLoading = false,
    this.loadingMessage,
    this.errorMessage,
    this.rawQuery = '',
    this.parsedIntent,
    this.recommendedPlaces = const [],
    this.selectedPlaces = const [],
    this.builtItinerary,
  });

  TripCreationState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? errorMessage,
    String? rawQuery,
    ParsedIntent? parsedIntent,
    List<Place>? recommendedPlaces,
    List<Place>? selectedPlaces,
    Itinerary? builtItinerary,
  }) {
    return TripCreationState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage,
      errorMessage: errorMessage,
      rawQuery: rawQuery ?? this.rawQuery,
      parsedIntent: parsedIntent ?? this.parsedIntent,
      recommendedPlaces: recommendedPlaces ?? this.recommendedPlaces,
      selectedPlaces: selectedPlaces ?? this.selectedPlaces,
      builtItinerary: builtItinerary ?? this.builtItinerary,
    );
  }
}

class TripCreationNotifier extends StateNotifier<TripCreationState> {
  final ApiClient _apiClient;

  TripCreationNotifier(this._apiClient) : super(TripCreationState());

  /// Step 1: Submit raw query to Gemini via Backend Proxy
  Future<bool> submitPrompt(String query) async {
    if (query.trim().isEmpty) return false;

    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Gemini sedang memahami rencana perjalanan Anda...',
      errorMessage: null,
      rawQuery: query,
    );

    try {
      final intent = await _apiClient.parseIntent(query);
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        parsedIntent: intent,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        errorMessage: 'Gagal menganalisis permintaan: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update parsed intent fields manually from confirmation card
  void updateParsedIntent(ParsedIntent newIntent) {
    state = state.copyWith(parsedIntent: newIntent);
  }

  /// Step 2: Search places from Places API / Datasets based on confirmed intent
  Future<bool> fetchPlacesForIntent() async {
    final intent = state.parsedIntent;
    if (intent == null) return false;

    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Mencari destinasi terbaik di ${intent.location}...',
      errorMessage: null,
    );

    try {
      final places = await _apiClient.searchPlaces(intent);
      // Pre-select top 4 places by default
      final defaultSelected = places.take(4).toList();

      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        recommendedPlaces: places,
        selectedPlaces: defaultSelected,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        errorMessage: 'Gagal mengambil rekomendasi tempat: ${e.toString()}',
      );
      return false;
    }
  }

  /// Toggle selection of place in recommendation list
  void togglePlaceSelection(Place place) {
    final current = [...state.selectedPlaces];
    final existsIndex = current.indexWhere((p) => p.placeId == place.placeId);

    if (existsIndex >= 0) {
      if (current.length > 1) {
        current.removeAt(existsIndex);
      }
    } else {
      current.add(place);
    }
    state = state.copyWith(selectedPlaces: current);
  }

  /// Step 3: Build optimized itinerary with Gemini + Directions API
  Future<bool> buildItinerary() async {
    if (state.selectedPlaces.isEmpty) {
      state = state.copyWith(errorMessage: 'Pilih minimal 1 tempat destinasi.');
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Menyusun urutan rute dan estimasi waktu perjalanan...',
      errorMessage: null,
    );

    try {
      final itinerary = await _apiClient.buildItinerary(
        state.selectedPlaces,
        intent: state.parsedIntent,
      );

      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        builtItinerary: itinerary,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        errorMessage: 'Gagal membuat itinerary: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reorder stops (drag & drop) in itinerary view
  void reorderStops(int oldIndex, int newIndex) {
    final itin = state.builtItinerary;
    if (itin == null) return;

    final places = [...itin.places];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = places.removeAt(oldIndex);
    places.insert(newIndex, item);

    // Re-assign order numbers
    final updated = places.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key + 1);
    }).toList();

    state = state.copyWith(
      builtItinerary: itin.copyWith(places: updated),
    );
  }

  /// Toggle visited status of a place
  void toggleVisited(String placeId) {
    final itin = state.builtItinerary;
    if (itin == null) return;

    final updated = itin.places.map((p) {
      if (p.placeId == placeId) {
        return p.copyWith(visited: !p.visited);
      }
      return p;
    }).toList();

    state = state.copyWith(
      builtItinerary: itin.copyWith(places: updated),
    );
  }

  /// Remove a place from current built itinerary
  void removePlaceFromItinerary(String placeId) {
    final itin = state.builtItinerary;
    if (itin == null || itin.places.length <= 1) return;

    final updated = itin.places.where((p) => p.placeId != placeId).toList();
    final reordered = updated.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key + 1);
    }).toList();

    state = state.copyWith(
      builtItinerary: itin.copyWith(places: reordered),
    );
  }

  void reset() {
    state = TripCreationState();
  }
}

final tripCreationProvider =
    StateNotifierProvider<TripCreationNotifier, TripCreationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TripCreationNotifier(apiClient);
});
