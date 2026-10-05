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
    List<Itinerary> localItineraries = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      localItineraries = jsonList.map((item) {
        return Itinerary.fromJson(jsonDecode(item) as Map<String, dynamic>);
      }).toList();

      state = localItineraries;
    } catch (e) {
      print('[SavedItineraries] Error loading saved: $e');
    }

    try {
      final remoteItineraries = await _apiClient.getItineraries();
      final mergedItineraries = [...remoteItineraries];
      final remoteIds = remoteItineraries.map((itinerary) => itinerary.id).toSet();
      for (final itinerary in localItineraries) {
        if (!remoteIds.contains(itinerary.id)) {
          mergedItineraries.add(await _apiClient.saveItinerary(itinerary));
        }
      }
      mergedItineraries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = mergedItineraries;
      await _persist();
    } catch (e) {
      print('[SavedItineraries] Cloud sync unavailable; using local data: $e');
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
    final persistedCopy = await _apiClient.saveItinerary(savedCopy);
    if (persistedCopy.shareCode != savedCopy.shareCode) {
      final persistedList = [...state];
      final persistedIndex =
          persistedList.indexWhere((i) => i.id == savedCopy.id);
      if (persistedIndex >= 0) {
        persistedList[persistedIndex] = persistedCopy;
        state = persistedList;
        await _persist();
      }
    }
  }

  Future<void> removeItinerary(String id) async {
    state = state.where((i) => i.id != id).toList();
    await _persist();
    try {
      await _apiClient.deleteItinerary(id);
    } catch (e) {
      print('[SavedItineraries] Cloud delete failed; kept local deletion: $e');
    }
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
    final updated = state.where((itin) => itin.id == itineraryId);
    if (updated.isNotEmpty) {
      await _apiClient.saveItinerary(updated.first);
    }
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
