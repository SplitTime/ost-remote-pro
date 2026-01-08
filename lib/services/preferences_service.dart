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
}