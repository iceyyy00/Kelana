import 'package:flutter_test/flutter_test.dart';
import 'package:kelana_app/core/network/api_client.dart';
import 'package:kelana_app/models/parsed_intent.dart';
import 'package:kelana_app/providers/trip_creation_provider.dart';

void main() {
  late ApiClient apiClient;

  setUp(() {
    apiClient = ApiClient(customBaseUrl: 'http://127.0.0.1:1/');
  });

  group('ApiClient.parseIntent guardrail', () {
    test('returns a local response for a short greeting', () async {
      final intent = await apiClient.parseIntent('  HALO  ');

      expect(intent.location, isEmpty);
      expect(intent.userNotes, contains('Halo!'));
      expect(intent.userNotes, contains('kota atau destinasi'));
      expect(intent.budget, 0);
      expect(intent.categories, isEmpty);
    });

    test('returns a local response for a query shorter than five characters',
        () async {
      final intent = await apiClient.parseIntent('Jog');

      expect(intent.location, isEmpty);
      expect(intent.userNotes, contains('Halo!'));
    });
  });

  group('ApiClient.handleLocalChitChat', () {
    test('matches normalized chit-chat phrases', () {
      expect(
        apiClient.handleLocalChitChat('  TERIMA KASIH '),
        startsWith('Sama-sama!'),
      );
      expect(
        apiClient.handleLocalChitChat('p'),
        contains('rencana perjalananmu'),
      );
    });

    test(
        'ParsedIntent retains chat response without inventing omitted defaults',
        () {
      final intent = ParsedIntent.fromJson({
        'location': '',
        'chat_response': 'Mau ke kota mana?',
      });

      expect(intent.chatResponse, 'Mau ke kota mana?');
      expect(intent.budget, 0);
      expect(intent.budgetLevel, 'unspecified');
      expect(intent.categories, isEmpty);
    });

    test('returns null for itinerary requests', () {
      expect(
        apiClient.handleLocalChitChat('Buat itinerary ke Bandung'),
        isNull,
      );
    });
  });

  test('TripCreationNotifier responds to greetings without parsing intent',
      () async {
    final notifier = TripCreationNotifier(apiClient);

    final result = await notifier.submitPrompt('hai');

    expect(result, isTrue);
    expect(notifier.state.rawQuery, 'hai');
    expect(notifier.state.conversationHistory, hasLength(2));
    expect(notifier.state.conversationHistory.last['text'],
        startsWith('Hai juga!'));
    expect(notifier.state.parsedIntent, isNull);
    expect(notifier.state.isLoading, isFalse);
    notifier.dispose();
  });

  test('provider carries local greeting history into the next intent request',
      () async {
    final fakeClient = _FakeApiClient();
    final notifier = TripCreationNotifier(fakeClient);

    await notifier.submitPrompt('halo');
    await notifier.submitPrompt('budget 100 juta');

    expect(fakeClient.receivedHistory, hasLength(2));
    expect(fakeClient.receivedHistory[0], {
      'role': 'user',
      'text': 'halo',
    });
    expect(fakeClient.receivedHistory[1]['role'], 'model');
    expect(fakeClient.receivedHistory[1]['text'], startsWith('Hai!'));
    expect(notifier.state.parsedIntent?.budget, 100000000);
    notifier.dispose();
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(customBaseUrl: 'http://127.0.0.1:1/');

  List<Map<String, String>> receivedHistory = const [];

  @override
  Future<ParsedIntent> parseIntent(
    String query, {
    Map<String, dynamic>? preferences,
    List<Map<String, String>> history = const [],
  }) async {
    receivedHistory = history;
    return ParsedIntent(
      location: '',
      budget: 100000000,
      budgetLevel: 'luxury',
      categories: const [],
      dateTime: 'Belum ditentukan',
      peopleCount: 1,
      userNotes: 'Masih perlu memilih kota.',
      chatResponse: 'Budget Rp 100.000.000 tercatat. Mau ke kota mana?',
    );
  }
}
