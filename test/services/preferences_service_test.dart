import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({}); // Start with empty prefs
  });

  test('PreferencesService singleton works correctly', () {
    final instance1 = PreferencesService();
    final instance2 = PreferencesService();
    expect(instance1, same(instance2));
  });

  test('PreferencesService should init with empty values', () async {
    final prefsService = PreferencesService();
    await prefsService.init();

    expect(prefsService.selectedEvent, '');
    expect(prefsService.selectedAidStation, '');
    expect(prefsService.selectedEventSlug, '');
  });

  test('PreferencesService should set and get values correctly', () async {
    final prefsService = PreferencesService();
    await prefsService.init();

    prefsService.selectedEvent = 'Test Event';
    prefsService.selectedAidStation = 'Test Station';
    prefsService.selectedEventSlug = 'test-event-slug';

    expect(prefsService.selectedEvent, 'Test Event');
    expect(prefsService.selectedAidStation, 'Test Station');
    expect(prefsService.selectedEventSlug, 'test-event-slug');
  });

  // --- Negative / edge case tests ---

  test('token returns null when not set', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    expect(prefsService.token, isNull);
  });

  test('setting token to null removes it', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.token = 'some-token';
    expect(prefsService.token, 'some-token');
    prefsService.token = null;
    expect(prefsService.token, isNull);
  });

  test('email returns null when not set', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    expect(prefsService.email, isNull);
  });

  test('setting email to null removes it', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.email = 'runner@example.com';
    expect(prefsService.email, 'runner@example.com');
    prefsService.email = null;
    expect(prefsService.email, isNull);
  });

  test('tokenExpiration returns null when not set', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    expect(prefsService.tokenExpiration, isNull);
  });

  test('clearAll removes all stored values', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.selectedEvent = 'My Event';
    prefsService.token = 'my-token';
    await prefsService.clearAll();
    expect(prefsService.selectedEvent, '');
    expect(prefsService.token, isNull);
  });

  test('clear with empty key clears all preferences', () async {
    // The clear() method treats an empty key as clearAll() — document this edge case
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.selectedEvent = 'Some Event';
    prefsService.selectedAidStation = 'Some Station';
    await prefsService.clear(''); // empty key triggers clearAll()
    expect(prefsService.selectedEvent, '');
    expect(prefsService.selectedAidStation, '');
  });

  test('bibNumberToAtheleteInfoForGivenEvent skips malformed JSON entries', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.participantInfoForSelectedEvent = [
      'not-valid-json',
      '{"bibNumber": "42", "fullName": "Valid Runner"}',
    ];
    final bibMap = prefsService.bibNumberToAtheleteInfoForGivenEvent;
    // Malformed entry is skipped; valid entry is parsed
    expect(bibMap.containsKey(42), true);
    expect(bibMap[42]?['fullName'], 'Valid Runner');
    expect(bibMap.length, 1);
  });

  test('bibNumberToAtheleteInfoForGivenEvent skips entries without bibNumber field', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.participantInfoForSelectedEvent = [
      '{"fullName": "No Bib Runner", "age": "30"}',
    ];
    final bibMap = prefsService.bibNumberToAtheleteInfoForGivenEvent;
    expect(bibMap.isEmpty, true);
  });

  test('bibNumberToAtheleteInfoForGivenEvent skips entries with non-numeric bibNumber', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.participantInfoForSelectedEvent = [
      '{"bibNumber": "not-a-number", "fullName": "Bad Bib"}',
    ];
    final bibMap = prefsService.bibNumberToAtheleteInfoForGivenEvent;
    expect(bibMap.isEmpty, true);
  });

  test('bibNumberToAtheleteInfoForGivenEvent returns empty map when list is empty', () async {
    final prefsService = PreferencesService();
    await prefsService.init();
    prefsService.participantInfoForSelectedEvent = [];
    final bibMap = prefsService.bibNumberToAtheleteInfoForGivenEvent;
    expect(bibMap.isEmpty, true);
  });
}
