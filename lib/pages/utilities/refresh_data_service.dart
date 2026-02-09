import 'dart:convert';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

/// Refresh Data behavior:
/// - Fetch full event details from server
/// - Update cached event metadata
/// - Import/overwrite entrant list locally
class RefreshDataService {
  final NetworkManager network;
  final PreferencesService _prefs = PreferencesService();

  RefreshDataService({required this.network});

  Future<void> refreshEventData({
    required String eventSlug,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);

    final Map<String, dynamic> object =
        await network.getEventDetailsRaw(eventSlug: eventSlug);

    onProgress?.call(0.85);

    // Save CurrentCourse fields
    final dataAttrs = object['data'] is Map<String, dynamic>
        ? (object['data'] as Map<String, dynamic>)['attributes']
        : null;

    if (dataAttrs is Map<String, dynamic>) {
      final dataEntryGroups = dataAttrs['dataEntryGroups'];
      if (dataEntryGroups != null) {
        _prefs.refreshDataEntryGroups = jsonEncode(dataEntryGroups);
      }

      final monitorPacers = dataAttrs['monitorPacers'];
      if (monitorPacers is bool) {
        _prefs.refreshMonitorPacers = monitorPacers;
      } else if (monitorPacers != null) {
        _prefs.refreshMonitorPacersJson = jsonEncode(monitorPacers);
      }

      // Save split names if present
      final splitNames =
          dataAttrs['splitNames'] ?? dataAttrs['parameterizedSplitNames'];
      if (splitNames is List) {
        final splits = splitNames
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (splits.isNotEmpty) {
          _prefs.refreshSplitNames = splits;
        }
      }
    }

    // Import efforts (entrant list)
    final included =
        object['included'] is List ? object['included'] as List : const [];

    final Map<String, String> bibToName = {};
    for (final item in included) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'efforts') continue;

      final attrs = item['attributes'];
      if (attrs is! Map<String, dynamic>) continue;

      final bib = attrs['bibNumber'];
      final name = attrs['fullName'];
      if (bib == null || name == null) continue;

      bibToName[bib.toString()] = name.toString();
    }

    _prefs.refreshBibToName = jsonEncode(bibToName);

    // Build eventIdsAndSplits + eventShortNames
    final Map<String, List<dynamic>> eventIdsAndSplits = {};
    final Map<String, String> eventShortNames = {};

    for (final item in included) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'events') continue;

      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final attrs = item['attributes'];
      if (attrs is! Map<String, dynamic>) continue;

      final shortName = attrs['shortName'];
      if (shortName is String && shortName.trim().isNotEmpty) {
        eventShortNames[id] = shortName.trim();
      }

      final splits = attrs['parameterizedSplitNames'];
      final list = eventIdsAndSplits[id] ?? <dynamic>[];
      list.add(splits);
      eventIdsAndSplits[id] = list;
    }

    _prefs.refreshEventIdsAndSplits = jsonEncode(eventIdsAndSplits);
    _prefs.refreshEventShortNames = jsonEncode(eventShortNames);
    _prefs.lastRefreshEpochMs = DateTime.now().millisecondsSinceEpoch;

    // Also refresh participant data for the existing participant cache
    await _prefs.refreshParticipantData();

    onProgress?.call(1.0);
  }
}
