import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:open_split_time_v2/services/preferences_service.dart';
import 'dart:developer' as developer;
import 'package:open_split_time_v2/services/network_manager.dart';

class ReviewSyncController extends ChangeNotifier {
  final NetworkManager _networkManager;
  final PreferencesService _prefs = PreferencesService();

  // State variables
  String? _sortBy = "Name"; // Default sort by Name
  String? _eventSlug;
  List<Map<String, dynamic>> _tableRows = [];
  List<Map<String, dynamic>> _localEntries = [];
  Map<int, Map<String, String>> _bibToName = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Sort options
  final List<String> sortByItems = [
    "Name",
    "Time Displayed",
    "Time Entered",
    "Bib #"
  ];

  // Constructor
  ReviewSyncController({NetworkManager? networkManager})
      : _networkManager = networkManager ?? NetworkManager();

  // Getters
  String? get sortBy => _sortBy;
  String? get eventSlug => _eventSlug;
  List<Map<String, dynamic>> get tableRows => _tableRows;
  List<Map<String, dynamic>> get localEntries => _localEntries;
  Map<int, Map<String, String>> get bibToName => _bibToName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialization
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      _eventSlug = _prefs.selectedEventSlug;
      developer.log('Selected event slug: $_eventSlug', name: 'ReviewSyncController');

      await _loadLocalEntries();
      await _loadBibToNameMapping();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
      developer.log('Error initializing ReviewSyncController: $e', name: 'ReviewSyncController');
    }
  }

  // Load local entries from preferences
  Future<void> _loadLocalEntries() async {
    try {
      final storedJson = _prefs.rawTimes;
      _localEntries = storedJson != null ? List<Map<String, dynamic>>.from(jsonDecode(storedJson)) : [];
      developer.log('Loaded ${_localEntries.length} local entries', name: 'ReviewSyncController');
      _updateTableRows();
    } catch (e) {
      developer.log('Error loading local entries: $e', name: 'ReviewSyncController');
      _localEntries = [];
    }
  }

  // Load bib number to name mapping
  Future<void> _loadBibToNameMapping() async {
    try {
      _bibToName = _prefs.bibNumberToAtheleteInfoForGivenEvent;
      developer.log('Loaded bib to name mapping with ${_bibToName.length} entries', name: 'ReviewSyncController');
    } catch (e) {
      developer.log('Error loading bib to name mapping: $e', name: 'ReviewSyncController');
      _bibToName = {};
    }
  }

  // Update sort by
  void updateSortBy(String? newSortBy) {
    if (newSortBy != null && sortByItems.contains(newSortBy)) {
      _sortBy = newSortBy;
      _updateTableRows();
      notifyListeners();
    }
  }

  // Update table rows based on current data and sorting
  void _updateTableRows() {
    _tableRows = _localEntries.map((entry) {
      final bibNumber = entry['attributes']?['bib_number']?.toString() ?? '';
      final name = _getNameForBib(bibNumber);
      final timeDisplayed = _formatTime(entry['attributes']?['entered_time']);
      final timeEntered = entry['attributes']?['entered_time']?.toString() ?? '';
      final splitName = entry['attributes']?['split_name']?.toString() ?? '';
      final subSplitKind = entry['attributes']?['sub_split_kind']?.toString() ?? '';
      final withPacer = entry['attributes']?['with_pacer']?.toString() ?? '';
      final stoppedHere = entry['attributes']?['stopped_here']?.toString() ?? '';

      return {
        'bibNumber': bibNumber,
        'name': name,
        'timeDisplayed': timeDisplayed,
        'timeEntered': timeEntered,
        'splitName': splitName,
        'subSplitKind': subSplitKind,
        'withPacer': withPacer,
        'stoppedHere': stoppedHere,
        'originalEntry': entry,
      };
    }).toList();

    _sortTableRows();
  }

  // Sort table rows based on current sort criteria
  void _sortTableRows() {
    _tableRows.sort((a, b) {
      switch (_sortBy) {
        case "Name":
          return (a['name'] as String).compareTo(b['name'] as String);
        case "Time Displayed":
          return (a['timeDisplayed'] as String).compareTo(b['timeDisplayed'] as String);
        case "Time Entered":
          return (a['timeEntered'] as String).compareTo(b['timeEntered'] as String);
        case "Bib #":
          final aBib = int.tryParse(a['bibNumber'] as String) ?? 0;
          final bBib = int.tryParse(b['bibNumber'] as String) ?? 0;
          return aBib.compareTo(bBib);
        default:
          return 0;
      }
    });
  }

  // Get name for bib number
  String _getNameForBib(String bibNumber) {
    try {
      final bib = int.parse(bibNumber);
      return _bibToName[bib]?['fullName'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Format time for display
  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      // Assuming timeString is in a format that can be parsed
      // This is a placeholder - adjust based on actual time format
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  // Sync entries to server
  Future<bool> syncEntries() async {
    if (_eventSlug == null || _eventSlug!.isEmpty) {
      _errorMessage = 'No event selected';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Prepare entries for sync (only unsynced ones)
      final unsyncedEntries = _localEntries.where((entry) =>
        entry['meta']?['synced'] != true
      ).toList();

      if (unsyncedEntries.isEmpty) {
        _errorMessage = 'No entries to sync';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      developer.log('Syncing ${unsyncedEntries.length} entries', name: 'ReviewSyncController');

      // Convert to JSONAPI batch format
      final payload = {
        'data': unsyncedEntries.map((entry) {
          return {
            'type': 'raw_time',
            'attributes': entry['attributes'],
          };
        }).toList(),
      };

      final success = await _networkManager.syncEntries(_eventSlug!, payload);

      if (success) {
        // Mark entries as synced
        for (var entry in unsyncedEntries) {
          entry['meta']?['synced'] = true;
        }
        _prefs.rawTimes = jsonEncode(_localEntries);
        await _loadLocalEntries(); // Refresh the list
        developer.log('Successfully synced entries', name: 'ReviewSyncController');
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to sync entries: $e';
      _isLoading = false;
      notifyListeners();
      developer.log('Error syncing entries: $e', name: 'ReviewSyncController');
      return false;
    }
  }

  // Delete entry at index
  void deleteEntry(int index) {
    if (index >= 0 && index < _localEntries.length) {
      _localEntries.removeAt(index);
      _prefs.rawTimes = jsonEncode(_localEntries);
      _updateTableRows();
      notifyListeners();
      developer.log('Deleted entry at index $index', name: 'ReviewSyncController');
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}