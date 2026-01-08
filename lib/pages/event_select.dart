import 'package:flutter/material.dart';
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
        // Set default selected event and aid stations if available
        if (_eventAidStations.isNotEmpty) {
          _selectedEvent = _eventAidStations.keys.first;
          _selectedAidStation = _eventAidStations[_selectedEvent!]!.isNotEmpty
              ? _eventAidStations[_selectedEvent!]!.first
              : null;
        }
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
                        onChanged: (value) {
                          setState(() {
                            _selectedEvent = value;
                            // Reset aid station selection when event changes
                            final stations = _eventAidStations[_selectedEvent!] ?? [];
                            _selectedAidStation = stations.isNotEmpty ? stations.first : null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomDropDownMenu(
                        items: _selectedEvent != null
                            ? _eventAidStations[_selectedEvent!] ?? []
                            : [],
                        hint: 'Select Aid Station',
                        onChanged: (value) {
                          setState(() {
                            _selectedAidStation = value;
                          });
                        },
                      ),
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