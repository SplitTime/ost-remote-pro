import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RawTimeEntry {
  final String eventSlug;
  final String splitName; // aid station / split
  final int bibNumber;
  final String subSplitKind; // "in" or "out"
  final bool stoppedHere;
  final String enteredTime; // keep as string for now (matches your json)

  RawTimeEntry({
    required this.eventSlug,
    required this.splitName,
    required this.bibNumber,
    required this.subSplitKind,
    required this.stoppedHere,
    required this.enteredTime,
  });

  Map<String, dynamic> toJson() => {
        'eventSlug': eventSlug,
        'splitName': splitName,
        'bibNumber': bibNumber,
        'subSplitKind': subSplitKind,
        'stoppedHere': stoppedHere,
        'enteredTime': enteredTime,
      };

  static RawTimeEntry fromJson(Map<String, dynamic> j) {
    return RawTimeEntry(
      eventSlug: (j['eventSlug'] ?? '').toString(),
      splitName: (j['splitName'] ?? '').toString(),
      bibNumber: (j['bibNumber'] ?? 0) is int
          ? (j['bibNumber'] as int)
          : int.tryParse((j['bibNumber'] ?? '0').toString()) ?? 0,
      subSplitKind: (j['subSplitKind'] ?? '').toString(),
      stoppedHere: (j['stoppedHere'] ?? false) == true,
      enteredTime: (j['enteredTime'] ?? '').toString(),
    );
  }
}

class RawTimeStore {
  static String _key(String eventSlug) => 'rawTimes:$eventSlug';

  /// Append an entry locally (for Cross Check + Review/Sync later).
  static Future<void> add(RawTimeEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final k = _key(entry.eventSlug);

    final current = prefs.getString(k);
    final List<dynamic> list =
        current == null ? [] : (jsonDecode(current) as List<dynamic>);

    list.add(entry.toJson());
    await prefs.setString(k, jsonEncode(list));
  }

  static Future<List<RawTimeEntry>> list(String eventSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(eventSlug));
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RawTimeEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
