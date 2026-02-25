import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/crosscheck/raw_time_store.dart';

void main() {
  group('RawTimeEntry', () {
    test('toJson produces correct map', () {
      final entry = RawTimeEntry(
        eventSlug: 'test-event',
        splitName: 'Aid Station 1',
        bibNumber: 42,
        subSplitKind: 'in',
        stoppedHere: false,
        enteredTime: '2024-06-15 14:30:45+02:00',
      );

      final json = entry.toJson();

      expect(json['eventSlug'], 'test-event');
      expect(json['splitName'], 'Aid Station 1');
      expect(json['bibNumber'], 42);
      expect(json['subSplitKind'], 'in');
      expect(json['stoppedHere'], false);
      expect(json['enteredTime'], '2024-06-15 14:30:45+02:00');
    });

    test('fromJson parses correct map', () {
      final json = {
        'eventSlug': 'marathon-2024',
        'splitName': 'Checkpoint A',
        'bibNumber': 100,
        'subSplitKind': 'out',
        'stoppedHere': true,
        'enteredTime': '2024-01-01 12:00:00-05:00',
      };

      final entry = RawTimeEntry.fromJson(json);

      expect(entry.eventSlug, 'marathon-2024');
      expect(entry.splitName, 'Checkpoint A');
      expect(entry.bibNumber, 100);
      expect(entry.subSplitKind, 'out');
      expect(entry.stoppedHere, true);
      expect(entry.enteredTime, '2024-01-01 12:00:00-05:00');
    });

    test('fromJson handles partially missing fields with defaults', () {
      final entry = RawTimeEntry.fromJson({
        'bibNumber': 0,
      });

      expect(entry.eventSlug, '');
      expect(entry.splitName, '');
      expect(entry.bibNumber, 0);
      expect(entry.subSplitKind, '');
      expect(entry.stoppedHere, false);
      expect(entry.enteredTime, '');
    });

    test('fromJson handles string bibNumber', () {
      final entry = RawTimeEntry.fromJson({
        'bibNumber': '55',
      });
      expect(entry.bibNumber, 55);
    });

    test('fromJson handles invalid bibNumber gracefully', () {
      final entry = RawTimeEntry.fromJson({
        'bibNumber': 'not-a-number',
      });
      expect(entry.bibNumber, 0);
    });

    test('roundtrip toJson -> fromJson preserves data', () {
      final original = RawTimeEntry(
        eventSlug: 'race-2024',
        splitName: 'Start Line',
        bibNumber: 7,
        subSplitKind: 'in',
        stoppedHere: true,
        enteredTime: '2024-03-15 08:00:00+00:00',
      );

      final restored = RawTimeEntry.fromJson(original.toJson());

      expect(restored.eventSlug, original.eventSlug);
      expect(restored.splitName, original.splitName);
      expect(restored.bibNumber, original.bibNumber);
      expect(restored.subSplitKind, original.subSplitKind);
      expect(restored.stoppedHere, original.stoppedHere);
      expect(restored.enteredTime, original.enteredTime);
    });
  });

  group('RawTimeStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('list returns empty list when no entries exist', () async {
      final entries = await RawTimeStore.list('nonexistent-event');
      expect(entries, isEmpty);
    });

    test('add stores an entry and list retrieves it', () async {
      final entry = RawTimeEntry(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        bibNumber: 10,
        subSplitKind: 'in',
        stoppedHere: false,
        enteredTime: '2024-06-15 14:30:45+02:00',
      );

      await RawTimeStore.add(entry);

      final entries = await RawTimeStore.list('test-event');
      expect(entries, hasLength(1));
      expect(entries[0].bibNumber, 10);
      expect(entries[0].splitName, 'Station 1');
    });

    test('add appends multiple entries', () async {
      final entry1 = RawTimeEntry(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        bibNumber: 10,
        subSplitKind: 'in',
        stoppedHere: false,
        enteredTime: '2024-06-15 14:30:45+02:00',
      );
      final entry2 = RawTimeEntry(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        bibNumber: 20,
        subSplitKind: 'out',
        stoppedHere: true,
        enteredTime: '2024-06-15 14:31:00+02:00',
      );

      await RawTimeStore.add(entry1);
      await RawTimeStore.add(entry2);

      final entries = await RawTimeStore.list('test-event');
      expect(entries, hasLength(2));
      expect(entries[0].bibNumber, 10);
      expect(entries[1].bibNumber, 20);
    });

    test('entries are scoped by eventSlug', () async {
      final entry1 = RawTimeEntry(
        eventSlug: 'event-a',
        splitName: 'Station 1',
        bibNumber: 1,
        subSplitKind: 'in',
        stoppedHere: false,
        enteredTime: '2024-06-15 14:30:45+02:00',
      );
      final entry2 = RawTimeEntry(
        eventSlug: 'event-b',
        splitName: 'Station 2',
        bibNumber: 2,
        subSplitKind: 'out',
        stoppedHere: false,
        enteredTime: '2024-06-15 14:31:00+02:00',
      );

      await RawTimeStore.add(entry1);
      await RawTimeStore.add(entry2);

      final eventAEntries = await RawTimeStore.list('event-a');
      final eventBEntries = await RawTimeStore.list('event-b');

      expect(eventAEntries, hasLength(1));
      expect(eventAEntries[0].bibNumber, 1);
      expect(eventBEntries, hasLength(1));
      expect(eventBEntries[0].bibNumber, 2);
    });

    test('list handles corrupted data gracefully', () async {
      // Manually set invalid JSON
      SharedPreferences.setMockInitialValues({
        'rawTimes:bad-event': 'not-valid-json',
      });

      final entries = await RawTimeStore.list('bad-event');
      expect(entries, isEmpty);
    });

    test('list handles non-list JSON gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'rawTimes:bad-event': '{"key": "value"}',
      });

      final entries = await RawTimeStore.list('bad-event');
      expect(entries, isEmpty);
    });
  });
}
