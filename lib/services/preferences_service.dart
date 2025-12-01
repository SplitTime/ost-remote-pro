import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Event Name
  String get selectedEvent => _prefs.getString('selected_event_key') ?? '';
  set selectedEvent(String value) => _prefs.setString('selected_event_key', value);

  // Aid Station Name
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
  String? get rawTimes => _prefs.getString('raw_times');
  set rawTimes(String? value) {
    if (value == null) {
      _prefs.remove('raw_times');
    } else {
      _prefs.setString('raw_times', value);
    }
  }
}