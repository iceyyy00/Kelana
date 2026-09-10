import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/itinerary.dart';
import '../core/network/api_client.dart';
import 'trip_creation_provider.dart';

class SavedItinerariesNotifier extends StateNotifier<List<Itinerary>> {
  final ApiClient _apiClient;
  static const String _storageKey = 'kelana_saved_itineraries';

  SavedItinerariesNotifier(this._apiClient) : super([]) {
    loadSaved();
  }

  Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      final loaded = jsonList.map((item) {
        return Itinerary.fromJson(jsonDecode(item) as Map<String, dynamic>);
      }).toList();

      state = loaded;
    } catch (e) {
      print('[SavedItineraries] Error loading saved: $e');
    }
  }

  Future<void> saveItinerary(Itinerary itinerary) async {
    final updatedList = [...state];
    final existingIdx = updatedList.indexWhere((i) => i.id == itinerary.id);

    final savedCopy = itinerary.copyWith(
      status: 'saved',
      shareCode: itinerary.shareCode ??
          'KLN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );

    if (existingIdx >= 0) {
      updatedList[existingIdx] = savedCopy;
    } else {
      updatedList.insert(0, savedCopy);
    }

    state = updatedList;
    await _persist();
    await _apiClient.saveItinerary(savedCopy);
  }

  Future<void> removeItinerary(String id) async {
    state = state.where((i) => i.id != id).toList();
    await _persist();
  }

  Future<void> togglePlaceVisited(String itineraryId, String placeId) async {
    state = state.map((itin) {
      if (itin.id == itineraryId) {
        final updatedPlaces = itin.places.map((p) {
          if (p.placeId == placeId) {
            return p.copyWith(visited: !p.visited);
          }
          return p;
        }).toList();
        return itin.copyWith(places: updatedPlaces);
      }
      return itin;
    }).toList();

    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = state.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_storageKey, stringList);
    } catch (e) {
      print('[SavedItineraries] Error persisting: $e');
    }
  }
}

final savedItinerariesProvider =
    StateNotifierProvider<SavedItinerariesNotifier, List<Itinerary>>((ref) {
  final client = ref.watch(apiClientProvider);
  return SavedItinerariesNotifier(client);
});
