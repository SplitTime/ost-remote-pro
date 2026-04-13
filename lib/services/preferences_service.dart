import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // clear all preferences (for testing or logout)
  Future<void> clearAll() async {
    if (!_initialized) return;
    await _prefs.clear();
  }

  Future<void> clear(String key) async {
    if (!_initialized) return;
    if (key.isEmpty) {
      await clearAll();
      return;
    }
    await _prefs.remove(key);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Event Name
  String get selectedEvent {
    if (!_initialized) return '';
    return _prefs.getString('selected_event_key') ?? '';
  }
  set selectedEvent(String value) {
    if (!_initialized) return;
    _prefs.setString('selected_event_key', value);
  }

  // Cached Aid Station Names
  List<String> get aidStationsForSelectedEvent {
    if (!_initialized) return [];
    return _prefs.getStringList('selected_event_aid_stations') ?? [];
  }
  set aidStationsForSelectedEvent(List<String> value) {
    if (!_initialized) return;
    _prefs.setStringList('selected_event_aid_stations', value);
  }

  // Cached Participant Information, easier to store on disk like this than map. Map can be easily rederived from simple JSON strings
  List<String> get participantInfoForSelectedEvent {
    if (!_initialized) return [];
    return _prefs.getStringList('selected_event_participant_information') ?? [];
  }
  set participantInfoForSelectedEvent(List<String> value) {
    if (!_initialized) return;
    _prefs.setStringList('selected_event_participant_information', value);
  }

  Map<int, Map<String, String>> get bibNumberToAtheleteInfoForGivenEvent {
    if (!_initialized) return {};
    final List<String> participantJSON = participantInfoForSelectedEvent;
    final Map<int, Map<String, String>> bibToInfo = {};
    for (var participantStr in participantJSON) {
      try {
        final Map<String, dynamic> participantMap = participantStr.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(participantStr)) : {};
        if (participantMap.containsKey('bibNumber')) {
          final int bibNumber = int.parse(participantMap['bibNumber'].toString());
          final String name = participantMap['fullName']?.toString() ?? '';
          final String origin = participantMap['origin']?.toString() ?? '';
          final String age = participantMap['age']?.toString() ?? '';
          final String gender = participantMap['gender']?.toString() ?? ''; 
          final String city = participantMap['city']?.toString() ?? '';
          final String stateCode = participantMap['stateCode']?.toString() ?? '';
          bibToInfo[bibNumber] = {
            'fullName': name,
            'origin': origin,
            'age': age,
            'gender': gender,
            'city': city,
            'stateCode': stateCode,
          };
        }
      } catch (e) {
        // Ignore malformed JSON entries
      }
    }
    return bibToInfo;
  }

  // Selected Aid Station Name
  String get selectedAidStation {
    if (!_initialized) return '';
    return _prefs.getString('selected_station_key') ?? '';
  }
  set selectedAidStation(String value) {
    if (!_initialized) return;
    _prefs.setString('selected_station_key', value);
  }

  // Event Slug
  String get selectedEventSlug {
    if (!_initialized) return '';
    return _prefs.getString('selected_event_slug_key') ?? '';
  }
  set selectedEventSlug(String value) {
    if (!_initialized) return;
    _prefs.setString('selected_event_slug_key', value);
  }



  // Login Token
  String? get token {
    if (!_initialized) return null;
    return _prefs.getString('token');
  }
  set token(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove('token');
    } else {
      _prefs.setString('token', value);
    }
  }

  // UUID for device ID
  static const String _deviceIDPrefix = 'ost-remote-2-';

  String _buildDeviceID() {
    return '$_deviceIDPrefix${Uuid().v4()}';
  }

  String get deviceID {
    if (!_initialized) return _buildDeviceID();
    String? id = _prefs.getString('device_id');
    if (id == null || !id.startsWith(_deviceIDPrefix)) {
      id = _buildDeviceID();
      _prefs.setString('device_id', id);
    }
    return id;
  }

  set deviceID(String? value) {
    if (!_initialized) return;
    if (value != null) {
      final normalizedValue = value.startsWith(_deviceIDPrefix) ? value : '$_deviceIDPrefix$value';
      _prefs.setString('device_id', normalizedValue);
    } else {
      _prefs.setString('device_id', _buildDeviceID());
    }
  }

  // Token Expiration
  DateTime? get tokenExpiration {
    if (!_initialized) return null;
    final timestamp = _prefs.getInt('token_expiration');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
  set tokenExpiration(DateTime? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove('token_expiration');
    } else {
      _prefs.setInt('token_expiration', value.millisecondsSinceEpoch);
    }
  }

  // Email
  String? get email {
    if (!_initialized) return null;
    return _prefs.getString('email');
  }
  set email(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove('email');
    } else {
      _prefs.setString('email', value);
    }
  }

  // raw_times storage
  String? get rawTimes {
    if (!_initialized) return null;
    return _prefs.getString('${selectedEventSlug}_raw_times');
  }
  set rawTimes(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove('${selectedEventSlug}_raw_times');
    } else {
      _prefs.setString('${selectedEventSlug}_raw_times', value);
    }
  }

  // Refresh participant data
  Future<int> refreshParticipantData() async {
    NetworkManager networkManager = NetworkManager();

    try {
      final List<String> participants = await networkManager.fetchParticipantDetailsForGivenEvent(eventSlug: selectedEventSlug);
      participantInfoForSelectedEvent = participants;
      return 1; // Success
    } catch (e) {
      return 0; // On error, return 0
    }
  }

  // --- Refresh cache properties (keyed by event slug) ---

  String _refreshKey(String suffix) => 'refresh:$selectedEventSlug:$suffix';

  String? get refreshDataEntryGroups {
    if (!_initialized) return null;
    return _prefs.getString(_refreshKey('dataEntryGroups'));
  }
  set refreshDataEntryGroups(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('dataEntryGroups'));
    } else {
      _prefs.setString(_refreshKey('dataEntryGroups'), value);
    }
  }

  bool? get refreshMonitorPacers {
    if (!_initialized) return null;
    final key = _refreshKey('monitorPacers');
    if (_prefs.containsKey(key)) return _prefs.getBool(key);
    return null;
  }
  set refreshMonitorPacers(bool? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('monitorPacers'));
    } else {
      _prefs.setBool(_refreshKey('monitorPacers'), value);
    }
  }

  String? get refreshMonitorPacersJson {
    if (!_initialized) return null;
    return _prefs.getString(_refreshKey('monitorPacersJson'));
  }
  set refreshMonitorPacersJson(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('monitorPacersJson'));
    } else {
      _prefs.setString(_refreshKey('monitorPacersJson'), value);
    }
  }

  List<String> get refreshSplitNames {
    if (!_initialized) return [];
    return _prefs.getStringList(_refreshKey('splitNames')) ?? [];
  }
  set refreshSplitNames(List<String> value) {
    if (!_initialized) return;
    _prefs.setStringList(_refreshKey('splitNames'), value);
  }

  String? get refreshBibToName {
    if (!_initialized) return null;
    return _prefs.getString(_refreshKey('bibToName'));
  }
  set refreshBibToName(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('bibToName'));
    } else {
      _prefs.setString(_refreshKey('bibToName'), value);
    }
  }

  String? get refreshEventIdsAndSplits {
    if (!_initialized) return null;
    return _prefs.getString(_refreshKey('eventIdsAndSplits'));
  }
  set refreshEventIdsAndSplits(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('eventIdsAndSplits'));
    } else {
      _prefs.setString(_refreshKey('eventIdsAndSplits'), value);
    }
  }

  String? get refreshEventShortNames {
    if (!_initialized) return null;
    return _prefs.getString(_refreshKey('eventShortNames'));
  }
  set refreshEventShortNames(String? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('eventShortNames'));
    } else {
      _prefs.setString(_refreshKey('eventShortNames'), value);
    }
  }

  int? get lastRefreshEpochMs {
    if (!_initialized) return null;
    return _prefs.getInt(_refreshKey('lastRefreshEpochMs'));
  }
  set lastRefreshEpochMs(int? value) {
    if (!_initialized) return;
    if (value == null) {
      _prefs.remove(_refreshKey('lastRefreshEpochMs'));
    } else {
      _prefs.setInt(_refreshKey('lastRefreshEpochMs'), value);
    }
  }
}