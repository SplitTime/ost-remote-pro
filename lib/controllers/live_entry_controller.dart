import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

// Utils
import 'dart:developer' as developer;
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/utils/time_utils.dart';

class LiveEntryController extends ChangeNotifier {
  // States for the live entry screen
  final NetworkManager _networkManager;

  final _prefs = PreferencesService();

  Map<int, Map<String, String>> _bibNumberToAtheleteInfo = {};

  DateTime? _entryTime;

  // Athlete Info
  String _bibNumber = '';
  String _athleteName = '';
  String _athleteOrigin = '';
  String _athleteGender = '';
  String _athleteAge = '';

  // Pacer and Continuing States
  bool _isContinuing = true;
  bool _hasPacer = false;

  // Event and Aid Station Info
  String _aidStation = '';
  String _eventName = '';
  String _eventSlug = '';

  // Constructor, if needed, can accept a NetworkManager for easier testing
  LiveEntryController({NetworkManager? networkManager})
      : _networkManager = networkManager ?? NetworkManager();

  // Methods to update states
  void updateBibNumber(String bibNumber) {
    _bibNumber = bibNumber;
    notifyListeners();
  }

  void updateAthleteName(String athleteName) {
    _athleteName = athleteName;
    notifyListeners();
  }

  void updateAthleteOrigin(String origin) {
    _athleteOrigin = origin;
    notifyListeners();
  }

  void updateAthleteGender(String gender) {
    _athleteGender = gender;
    notifyListeners();
  }

  void updateAthleteAge(String age) {
    _athleteAge = age;
    notifyListeners();
  }

  void toggleIsContinuing(bool value) {
    _isContinuing = value;
    notifyListeners();
  }

  void toggleHasPacer(bool value) {
    _hasPacer = value;
    notifyListeners();
  }

  void updateAidStation(String station) {
    _aidStation = station;
    notifyListeners();
  }

  void updateEventName(String name) {
    _eventName = name;
    notifyListeners();
  }

  void updateEventSlug(String slug) {
    _eventSlug = slug;
    notifyListeners();
  }

  // Getters
  String get bibNumber => _bibNumber;
  String get athleteName => _athleteName;
  bool get isContinuing => _isContinuing;
  bool get hasPacer => _hasPacer;
  DateTime? get entryTime => _entryTime;
  String get aidStation => _aidStation;
  String get eventName => _eventName;
  String get eventSlug => _eventSlug;
  String get athleteOrigin => _athleteOrigin;
  String get athleteGender => _athleteGender;
  String get athleteAge => _athleteAge;

  // load participants
  Future<void> loadParticipants() async {
    try {
      final participants =
          await _networkManager.fetchParticipantNames(eventName: eventSlug);
      _bibNumberToAtheleteInfo = participants;
      notifyListeners();
    } catch (e) {
      developer.log('Error loading participants: $e',
          name: 'LiveEntryController');
    }
  }

  // update athlete info based on bib number
  void updateAthleteInfo() {
    if (_bibNumber.isNotEmpty) {
      try {
        final bib = int.parse(_bibNumber);
        updateAthleteName(_bibNumberToAtheleteInfo[bib]?['fullName'] ?? '');
        updateAthleteAge(_bibNumberToAtheleteInfo[bib]?['age'] ?? '');
        updateAthleteGender(_bibNumberToAtheleteInfo[bib]?['gender'] ?? '');
        final city = _bibNumberToAtheleteInfo[bib]?['city'] ?? '';
        final state = _bibNumberToAtheleteInfo[bib]?['stateCode'] ?? '';
        final origin =
            '$city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state'
                .trim();
        updateAthleteOrigin(origin);
      } catch (e) {
        updateAthleteName('');
        updateAthleteAge('');
        updateAthleteGender('');
        updateAthleteOrigin('');
      }
    } else {
      updateAthleteName('');
      updateAthleteAge('');
      updateAthleteGender('');
      updateAthleteOrigin('');
    }
  }

  // Method to handle station control logic
  void stationControl(String inOut, String source) {
    // assert inOut is either 'in' or 'out'
    assert(
        inOut == 'in' || inOut == 'out', 'inOut must be either "in" or "out"');

    // assert source is not empty
    assert(source.isNotEmpty, 'source must not be empty');

    _entryTime = DateTime.now();

    // if bibNumber is not found in _bibNumberToName, log and return
    if (_bibNumberToAtheleteInfo[int.parse(_bibNumber)] == null) {
      developer.log('Bib number not found: $_bibNumber',
          name: 'LiveEntryController');
      return;
    }
    final json = {
      'type': 'raw_time',
      'attributes': {
        'source': source,
        'sub_split_kind': inOut,
        'with_pacer': _hasPacer.toString(),
        'entered_time': TimeUtils.formatEnteredTimeLocal(),
        'split_name': aidStation,
        'bib_number': _bibNumber,
        'stopped_here': (!_isContinuing).toString(),
      },
      'meta': {
        'synced': false,
      },
    };

    // Log the JSON being sent
    developer.log('Submitting time entry: $json', name: 'LiveEntryScreen');

    // Record the data in the backend, wait for networkManager to send the data
    appendEntry(json);
  }

  void appendEntry(newEntryJson) async {
    // Get SharedPreferences instance
    // TODO: Replace with PreferencesService

    // Get existing list OR create a new empty list
    final storedJson = _prefs.rawTimes;
    List<dynamic> list = storedJson != null ? jsonDecode(storedJson) : [];

    // Add the new entry
    list.add(newEntryJson);

    // Save updated list
    _prefs.rawTimes = jsonEncode(list);
  }
}
