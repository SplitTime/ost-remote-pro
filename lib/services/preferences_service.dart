import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'dart:convert';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;

  // clear all preferences (for testing or logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  Future<void> clear(String key) async {
    if(key == null || key.isEmpty) {
      // Just clear everything in the event of an empty key, perhaps we could discuss if this should error
      await clearAll();
      return;
    }
    await _prefs.remove(key);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Event Name
  String get selectedEvent => _prefs.getString('selected_event_key') ?? '';
  set selectedEvent(String value) => _prefs.setString('selected_event_key', value);

  // Cached Aid Station Names
  List<String> get aidStationsForSelectedEvent => _prefs.getStringList('selected_event_aid_stations') ?? [];
  set aidStationsForSelectedEvent(List<String> value) => _prefs.setStringList('se_aid_stations', value);

  // Cached Participant Information, easier to store on disk like this than map. Map can be easily rederived from simple JSON strings
  List<String> get participantInfoForSelectedEvent => _prefs.getStringList('selected_event_participant_information') ?? [];
  set participantInfoForSelectedEvent(List<String> value) => _prefs.setStringList('selected_event_participant_information', value);

  Map<int, Map<String, String>> get bibNumberToAtheleteInfoForGivenEvent {
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
  String get selectedAidStation => _prefs.getString('selected_station_key') ?? '';
  set selectedAidStation(String value) => _prefs.setString('selected_station_key', value);

  // Event Slug
  String get selectedEventSlug => _prefs.getString('selected_event_slug_key') ?? '';
  set selectedEventSlug(String value) => _prefs.setString('selected_event_slug_key', value);



  // Login Token
  String? get token => _prefs.getString('token');
  set token(String? value) {
    if (value == null) {
      _prefs.remove('token');
    } else {
      _prefs.setString('token', value);
    }
  }

  // Token Expiration
  DateTime? get tokenExpiration {
    final timestamp = _prefs.getInt('token_expiration');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
  set tokenExpiration(DateTime? value) {
    if (value == null) {
      _prefs.remove('token_expiration');
    } else {
      _prefs.setInt('token_expiration', value.millisecondsSinceEpoch);
    }
  }

  // Email
  String? get email => _prefs.getString('email');
  set email(String? value) {
    if (value == null) {
      _prefs.remove('email');
    } else {
      _prefs.setString('email', value);
    }
  }

  // raw_times storage
  String? get rawTimes => _prefs.getString('${selectedEventSlug}_raw_times');
  set rawTimes(String? value) {
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
      print(participantInfoForSelectedEvent);
      return 1; // Success
    } catch (e) {
      return 0; // On error, return 0
    }
  }
  
}