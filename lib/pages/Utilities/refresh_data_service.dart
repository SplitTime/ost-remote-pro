import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/network_manager.dart';

/// Refresh Data behavior:
/// - Fetch full event details from server
/// - Update cached event metadata
/// - Import/overwrite entrant list locally
class RefreshDataService {
  final NetworkManager network;

  RefreshDataService({required this.network});

  Future<void> refreshEventData({
    required String eventSlug,
    void Function(double progress)? onProgress,
  }) async {
    // iOS sets progress to 0.5 immediately after showing loading
    onProgress?.call(0.5);

    final Map<String, dynamic> object =
        await network.getEventDetailsRaw(eventSlug: eventSlug);

    // iOS sets progress to 1 after the network returns
    onProgress?.call(0.85);

    final prefs = await SharedPreferences.getInstance();

    // --- Save iOS-equivalent CurrentCourse fields (as JSON blobs) ---
    final dataAttrs = object['data'] is Map<String, dynamic>
        ? (object['data'] as Map<String, dynamic>)['attributes']
        : null;

    if (dataAttrs is Map<String, dynamic>) {
      final dataEntryGroups = dataAttrs['dataEntryGroups'];
      if (dataEntryGroups != null) {
        await prefs.setString(
          _k(eventSlug, 'dataEntryGroups'),
          jsonEncode(dataEntryGroups),
        );
      }

      final monitorPacers = dataAttrs['monitorPacers'];
      if (monitorPacers is bool) {
        await prefs.setBool(_k(eventSlug, 'monitorPacers'), monitorPacers);
      } else if (monitorPacers != null) {
        await prefs.setString(
          _k(eventSlug, 'monitorPacersJson'),
          jsonEncode(monitorPacers),
        );
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
          await prefs.setStringList(_k(eventSlug, 'splitNames'), splits);
        }
      }
    }

    // --- Import efforts (entrant list) ---
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

    await prefs.setString(_k(eventSlug, 'bibToName'), jsonEncode(bibToName));

    // --- Build eventIdsAndSplits + eventShortNames (same as iOS) ---
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

    await prefs.setString(
        _k(eventSlug, 'eventIdsAndSplits'), jsonEncode(eventIdsAndSplits));
    await prefs.setString(
        _k(eventSlug, 'eventShortNames'), jsonEncode(eventShortNames));

    await prefs.setInt(
      _k(eventSlug, 'lastRefreshEpochMs'),
      DateTime.now().millisecondsSinceEpoch,
    );

    onProgress?.call(1.0);
  }

  static String _k(String eventSlug, String suffix) =>
      'refresh:$eventSlug:$suffix';
}
