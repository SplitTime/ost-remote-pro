import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/widgets/dropdown_menu.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

class EventSelect extends StatefulWidget {
  const EventSelect({super.key});

  @override
  State<EventSelect> createState() => _EventSelectState();
}

class _EventSelectState extends State<EventSelect> {
  final PreferencesService prefs = PreferencesService();
  final NetworkManager _networkManager = NetworkManager();
  Map<String, List<String>> _eventAidStations = {};
  String? _selectedEvent;
  String? _selectedAidStation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEvent = prefs.selectedEvent;
    _selectedAidStation = prefs.selectedAidStation;
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedEventSlug', eventSlug ?? '');
        await prefs.setString('selectedAidStation', _selectedAidStation!);
        await prefs.setString('selectedEvent', _selectedEvent!);
      } catch (e) {
        print("$e"); // Basic debug, consider better handling later.
      }
      if (eventSlug != null) {
        // Save selections to preferences
        prefs.selectedEvent = _selectedEvent!;
        prefs.selectedAidStation = _selectedAidStation!;

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