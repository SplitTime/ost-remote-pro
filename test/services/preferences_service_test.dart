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
}
