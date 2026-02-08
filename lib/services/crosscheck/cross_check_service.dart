import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/crosscheck/raw_time_store.dart';
import 'package:open_split_time_v2/services/network_manager.dart';

enum CrossCheckStatus { recorded, stopped, expected, notExpected }

class CrossCheckItem {
  final int bib;
  final CrossCheckStatus status;
  final bool isSelectable; // only expected / notExpected
  final bool isSelected;

  CrossCheckItem({
    required this.bib,
    required this.status,
    required this.isSelectable,
    required this.isSelected,
  });
}

class CrossCheckViewModel {
  final List<CrossCheckItem> items;
  final Map<CrossCheckStatus, int> counts;

  CrossCheckViewModel({required this.items}) : counts = _count(items);

  static Map<CrossCheckStatus, int> _count(List<CrossCheckItem> items) {
    final m = <CrossCheckStatus, int>{
      CrossCheckStatus.recorded: 0,
      CrossCheckStatus.stopped: 0,
      CrossCheckStatus.expected: 0,
      CrossCheckStatus.notExpected: 0,
    };
    for (final i in items) {
      m[i.status] = (m[i.status] ?? 0) + 1;
    }
    return m;
  }
}

class CrossCheckService {
  final NetworkManager network;

  CrossCheckService({required this.network});

  static String _flagsKey(String eventSlug, String splitName) =>
      'crosscheck:$eventSlug:$splitName:flags'; // bib -> bool(notExpected)

  Future<Map<int, bool>> _loadFlags(String eventSlug, String splitName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_flagsKey(eventSlug, splitName));
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <int, bool>{};
      decoded.forEach((k, v) {
        final bib = int.tryParse(k.toString());
        if (bib != null) out[bib] = (v == true);
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveFlags(
      String eventSlug, String splitName, Map<int, bool> flags) async {
    final prefs = await SharedPreferences.getInstance();
    final asStringKey = <String, bool>{};
    flags.forEach((k, v) => asStringKey[k.toString()] = v);
    await prefs.setString(_flagsKey(eventSlug, splitName), jsonEncode(asStringKey));
  }

  Future<void> refreshFlagsFromServer({
    required String eventSlug,
    required String splitName,
  }) async {
    // If you haven't implemented this endpoint, it can safely do nothing.
    final Map<int, bool>? serverFlags = await network.fetchCrossCheckFlags(
      eventSlug: eventSlug,
      splitName: splitName,
    );

    if (serverFlags != null) {
      await _saveFlags(eventSlug, splitName, serverFlags);
    }
  }

  // UPDATED: accept bibMap
  Future<CrossCheckViewModel> build({
    required String eventSlug,
    required String splitName,
    required Set<int> selectedBibs,
    Map<int, String>? bibMap,
  }) async {
    final bibs = <int>{};

    // 1) Prefer bibs passed from the caller (LiveEntry has it in memory)
    if (bibMap != null && bibMap.isNotEmpty) {
      bibs.addAll(bibMap.keys);
    }

    // 2) Always include any locally entered bibs (so grid still works offline)
    final entries = await RawTimeStore.list(eventSlug);
    for (final e in entries) {
      bibs.add(e.bibNumber);
    }

    // Split-specific entries
    final stationEntries = entries.where((e) => e.splitName == splitName).toList();

    final recorded = <int>{};
    final stopped = <int>{};
    for (final e in stationEntries) {
      recorded.add(e.bibNumber);
      if (e.stoppedHere) stopped.add(e.bibNumber);
    }

    final flags = await _loadFlags(eventSlug, splitName); // bib -> notExpected?

    final list = bibs.toList()..sort();

    final items = <CrossCheckItem>[];
    for (final bib in list) {
      CrossCheckStatus status;
      if (stopped.contains(bib)) {
        status = CrossCheckStatus.stopped;
      } else if (recorded.contains(bib)) {
        status = CrossCheckStatus.recorded;
      } else {
        final notExpected = flags[bib] == true;
        status = notExpected ? CrossCheckStatus.notExpected : CrossCheckStatus.expected;
      }

      final selectable =
          status == CrossCheckStatus.expected || status == CrossCheckStatus.notExpected;

      items.add(CrossCheckItem(
        bib: bib,
        status: status,
        isSelectable: selectable,
        isSelected: selectable && selectedBibs.contains(bib),
      ));
    }

    return CrossCheckViewModel(items: items);
  }

  Future<void> setSelectedToExpected({
    required String eventSlug,
    required String splitName,
    required Set<int> selectedBibs,
  }) async {
    final flags = await _loadFlags(eventSlug, splitName);
    for (final bib in selectedBibs) {
      flags[bib] = false;
    }
    await _saveFlags(eventSlug, splitName, flags);
  }

  Future<void> setSelectedToNotExpected({
    required String eventSlug,
    required String splitName,
    required Set<int> selectedBibs,
  }) async {
    final flags = await _loadFlags(eventSlug, splitName);
    for (final bib in selectedBibs) {
      flags[bib] = true;
    }
    await _saveFlags(eventSlug, splitName, flags);
  }
}
