import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/widgets/dropdown_menu.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

import 'dart:developer' as developer;

class EventSelect extends StatefulWidget {
  const EventSelect({super.key});

  @override
  State<EventSelect> createState() => _EventSelectState();
}

class _EventSelectState extends State<EventSelect> {
  final PreferencesService _prefs = PreferencesService();
  final NetworkManager _networkManager = NetworkManager();
  Map<String, List<String>> _eventAidStations = {};
  String? _selectedEvent;
  String? _selectedAidStation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEvent = _prefs.selectedEvent;
    _selectedAidStation = _prefs.selectedAidStation;
    if (_selectedAidStation == '') {
      _selectedAidStation = null;
    }
    if (_selectedEvent == '') {
      _selectedEvent = null;
    }

    developer.log(
      'Loaded selected event: $_selectedEvent, aid station: $_selectedAidStation',
      name: 'EventSelect.initState',
    );
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final eventAidStations = await _networkManager.fetchEventDetails();
      setState(() {
        _eventAidStations = eventAidStations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToLiveEntry(BuildContext context) async {
    if (_selectedEvent != null && _selectedAidStation != null) {
      // First get the event slug
      final eventSlug = await _networkManager.getEventSlugByName(_selectedEvent!);
      try {
        _prefs.selectedEventSlug = eventSlug ?? '';
        _prefs.selectedEvent = _selectedEvent!;
        _prefs.selectedAidStation = _selectedAidStation!;
        developer.log(  
          '${_prefs.selectedEventSlug}, ${_prefs.selectedEvent}, ${_prefs.selectedAidStation}',
          name: 'EventSelect._navigateToLiveEntry',
        );
      } catch (e) {
        print("$e"); // Basic debug, consider better handling later.
      }
      if (eventSlug != null) {
        // Save selections to preferences
        _prefs.aidStationsForSelectedEvent = _eventAidStations[_selectedEvent] ?? [];
        List<String> participantInfo = [];
        Map<int, Map<String,String>> participantJSON = await _networkManager.fetchParticipantNames(eventName: eventSlug);
        print(participantJSON);

        if (!mounted) return; // Safety check if widget was disposed
        Navigator.pushNamed(
          context,
          '/liveEntry',
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find event details.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both event and aid station.'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Event'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEventDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CustomDropDownMenu(
                        items: _eventAidStations.keys.toList(),
                        hint: 'Select Event',
                        value: _selectedEvent,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedEvent = newValue;
                            _selectedAidStation = null; // Reset aid station when event changes
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomDropDownMenu(
                        items: _selectedEvent != null
                            ? _eventAidStations[_selectedEvent!] ?? []
                            : [],
                        hint: 'Select Aid Station',
                        value: _selectedAidStation,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedAidStation = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async => await _navigateToLiveEntry(context),
                        child: const Text('Begin Live Entry'),
                      )
                    ],
                  ),
      ),
    );
  }
}