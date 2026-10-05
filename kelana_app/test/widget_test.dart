// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kelana_app/main.dart';
import 'package:kelana_app/core/network/api_client.dart';
import 'package:kelana_app/models/itinerary.dart';
import 'package:kelana_app/models/place.dart';
import 'package:kelana_app/providers/trip_creation_provider.dart';

void main() {
  test('opening a saved itinerary restores active trip state', () {
    final itinerary = Itinerary(
      id: 'saved-1',
      title: 'Semarang day trip',
      summary: 'A saved route',
      createdAt: '2026-10-05T09:00:00.000Z',
      location: 'Semarang',
      places: [
        Place.fromJson({'placeId': 'bad', 'name': 'C 2301'}),
        Place.fromJson({'placeId': 'good', 'name': 'Lawang Sewu'}),
      ],
    );
    final notifier = TripCreationNotifier(ApiClient());

    notifier.openItinerary(itinerary);

    expect(notifier.state.builtItinerary?.id, itinerary.id);
    expect(
      notifier.state.builtItinerary?.places.map((place) => place.placeId),
      ['good'],
    );
    expect(notifier.state.recommendedPlaces.map((place) => place.placeId),
        ['good']);
    expect(
        notifier.state.selectedPlaces.map((place) => place.placeId), ['good']);
    notifier.dispose();
  });

  testWidgets('KelanaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KelanaApp(),
      ),
    );
    expect(find.byType(KelanaApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
