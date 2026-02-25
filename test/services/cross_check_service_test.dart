import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/crosscheck/cross_check_service.dart';
import 'package:open_split_time_v2/services/crosscheck/raw_time_store.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

/// Manual mock that overrides fetchCrossCheckFlags to always return null
/// (simulates no server flags / offline).
class FakeNetworkManager extends NetworkManager {
  @override
  Future<Map<int, bool>?> fetchCrossCheckFlags({
    required String eventSlug,
    required String splitName,
  }) async {
    return null;
  }

  @override
  Future<String?> getToken() async => 'fake-token';
}

void main() {
  late FakeNetworkManager fakeNetwork;
  late CrossCheckService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeNetwork = FakeNetworkManager();
    service = CrossCheckService(network: fakeNetwork);
    // Init PreferencesService for the fake network parent
    await PreferencesService().init();
  });

  group('CrossCheckItem', () {
    test('creates with correct properties', () {
      final item = CrossCheckItem(
        bib: 42,
        status: CrossCheckStatus.recorded,
        isSelectable: false,
        isSelected: false,
      );

      expect(item.bib, 42);
      expect(item.status, CrossCheckStatus.recorded);
      expect(item.isSelectable, false);
      expect(item.isSelected, false);
    });

    test('expected and notExpected items are selectable', () {
      final expected = CrossCheckItem(
        bib: 1,
        status: CrossCheckStatus.expected,
        isSelectable: true,
        isSelected: false,
      );
      final notExpected = CrossCheckItem(
        bib: 2,
        status: CrossCheckStatus.notExpected,
        isSelectable: true,
        isSelected: false,
      );

      expect(expected.isSelectable, true);
      expect(notExpected.isSelectable, true);
    });
  });

  group('CrossCheckViewModel', () {
    test('counts items by status correctly', () {
      final items = [
        CrossCheckItem(bib: 1, status: CrossCheckStatus.recorded, isSelectable: false, isSelected: false),
        CrossCheckItem(bib: 2, status: CrossCheckStatus.recorded, isSelectable: false, isSelected: false),
        CrossCheckItem(bib: 3, status: CrossCheckStatus.stopped, isSelectable: false, isSelected: false),
        CrossCheckItem(bib: 4, status: CrossCheckStatus.expected, isSelectable: true, isSelected: false),
        CrossCheckItem(bib: 5, status: CrossCheckStatus.expected, isSelectable: true, isSelected: false),
        CrossCheckItem(bib: 6, status: CrossCheckStatus.expected, isSelectable: true, isSelected: false),
        CrossCheckItem(bib: 7, status: CrossCheckStatus.notExpected, isSelectable: true, isSelected: false),
      ];

      final vm = CrossCheckViewModel(items: items);

      expect(vm.counts[CrossCheckStatus.recorded], 2);
      expect(vm.counts[CrossCheckStatus.stopped], 1);
      expect(vm.counts[CrossCheckStatus.expected], 3);
      expect(vm.counts[CrossCheckStatus.notExpected], 1);
    });

    test('counts are zero for empty list', () {
      final vm = CrossCheckViewModel(items: []);

      expect(vm.counts[CrossCheckStatus.recorded], 0);
      expect(vm.counts[CrossCheckStatus.stopped], 0);
      expect(vm.counts[CrossCheckStatus.expected], 0);
      expect(vm.counts[CrossCheckStatus.notExpected], 0);
    });
  });

  group('CrossCheckService.build', () {
    test('returns empty viewmodel when no bibs exist', () async {
      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
      );

      expect(vm.items, isEmpty);
    });

    test('marks recorded bibs from RawTimeStore', () async {
      await RawTimeStore.add(RawTimeEntry(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        bibNumber: 42,
        subSplitKind: 'in',
        stoppedHere: false,
        enteredTime: '2024-06-15 14:30:45+02:00',
      ));

      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
      );

      expect(vm.items, hasLength(1));
      expect(vm.items[0].bib, 42);
      expect(vm.items[0].status, CrossCheckStatus.recorded);
      expect(vm.items[0].isSelectable, false);
    });

    test('marks stopped bibs correctly', () async {
      await RawTimeStore.add(RawTimeEntry(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        bibNumber: 99,
        subSplitKind: 'in',
        stoppedHere: true,
        enteredTime: '2024-06-15 14:30:45+02:00',
      ));

      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
      );

      expect(vm.items[0].status, CrossCheckStatus.stopped);
    });

    test('bibs from bibMap without entries are marked expected by default', () async {
      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
        bibMap: {10: 'Runner A', 20: 'Runner B'},
      );

      expect(vm.items, hasLength(2));
      expect(vm.items[0].status, CrossCheckStatus.expected);
      expect(vm.items[1].status, CrossCheckStatus.expected);
    });

    test('selected bibs are marked as selected', () async {
      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {10},
        bibMap: {10: 'Runner A', 20: 'Runner B'},
      );

      final bib10 = vm.items.firstWhere((i) => i.bib == 10);
      final bib20 = vm.items.firstWhere((i) => i.bib == 20);

      expect(bib10.isSelected, true);
      expect(bib20.isSelected, false);
    });

    test('items are sorted by bib number', () async {
      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
        bibMap: {30: 'C', 10: 'A', 20: 'B'},
      );

      expect(vm.items[0].bib, 10);
      expect(vm.items[1].bib, 20);
      expect(vm.items[2].bib, 30);
    });
  });

  group('CrossCheckService.setSelectedToExpected', () {
    test('marks selected bibs as expected (flag = false)', () async {
      // First mark as not expected
      await service.setSelectedToNotExpected(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {10, 20},
      );

      // Then mark bib 10 as expected
      await service.setSelectedToExpected(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {10},
      );

      // Build and check
      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
        bibMap: {10: 'A', 20: 'B'},
      );

      final bib10 = vm.items.firstWhere((i) => i.bib == 10);
      final bib20 = vm.items.firstWhere((i) => i.bib == 20);

      expect(bib10.status, CrossCheckStatus.expected);
      expect(bib20.status, CrossCheckStatus.notExpected);
    });
  });

  group('CrossCheckService.setSelectedToNotExpected', () {
    test('marks selected bibs as not expected (flag = true)', () async {
      await service.setSelectedToNotExpected(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {10},
      );

      final vm = await service.build(
        eventSlug: 'test-event',
        splitName: 'Station 1',
        selectedBibs: {},
        bibMap: {10: 'A'},
      );

      expect(vm.items[0].status, CrossCheckStatus.notExpected);
    });
  });
}
