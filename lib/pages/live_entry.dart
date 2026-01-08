// live_entry.dart
import 'package:flutter/material.dart';

// Widgets
import 'package:open_split_time_v2/widgets/live_entry_widgets/clock.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/numpad.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';

import 'package:open_split_time_v2/widgets/live_entry_widgets/station_status_display.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/edit_bottom_sheet.dart';

// Controller
import 'package:open_split_time_v2/controllers/live_entry_controller.dart';

// Services
import 'package:open_split_time_v2/services/preferences_service.dart';

class LiveEntryScreen extends StatefulWidget {
  const LiveEntryScreen({super.key});

  @override
  State<LiveEntryScreen> createState() => _LiveEntryScreenState();
}

class _LiveEntryScreenState extends State<LiveEntryScreen> {
  final LiveEntryController _controller = LiveEntryController();
  final PreferencesService _prefs = PreferencesService();

  bool _isStationPressed = false;
  bool _isLoading = true;

  void _showEditSheet() {
    // Format date and time separately
    final dateStr =
        "${_controller.entryTime!.year}-${_controller.entryTime!.month.toString().padLeft(2, '0')}-${_controller.entryTime!.day.toString().padLeft(2, '0')}";
    final timeStr =
        "${_controller.entryTime!.hour.toString().padLeft(2, '0')}:${_controller.entryTime!.minute.toString().padLeft(2, '0')}:${_controller.entryTime!.second.toString().padLeft(2, '0')}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to grow if needed
      builder: (context) {
        return EditEntryBottomSheet(
          eventName: _controller.eventName,
          bibNumber: _controller.bibNumber,
          athleteName: _controller.athleteName,
          date: dateStr,
          time: timeStr,
          isContinuing: _controller
              .isContinuing, // Assuming current toggle state, or store last state if needed
          hasPacer: _controller.hasPacer,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // We can't access widget.parameters in initState, so we'll load data in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    _controller.updateAidStation(_prefs.selectedAidStation);
    _controller.updateEventName(_prefs.selectedEvent);
    _controller.updateEventSlug(_prefs.selectedEventSlug);

    _controller.loadParticipants().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _updateAthleteInfo() {
    _controller.updateAthleteInfo();
    setState(() {
      _isStationPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Entry'),
      ),
      endDrawer: const PageRouterDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // --- Top: Bib number and name ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... Left Column (Bib display) ...
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(_controller.bibNumber,
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w900)),
                      // ... Time of day ...
                      Center(child: ClockWidget()),
                    ],
                  ),
                ),
                // ... Right Column (Name / Green Box) ...
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _isLoading
                                ? const CircularProgressIndicator()
                                : Text(_controller.athleteName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),

                            // --- MODIFIED GREEN BOX SECTION ---
                            StationStatusDisplay(
                              isStationPressed: _isStationPressed,
                              atheleteOrigin: _controller.athleteOrigin,
                              showEditSheet: _showEditSheet,
                              lastBib: _controller.bibNumber,
                              lastEntryTime: _controller.entryTime,
                            ),
                          ],
                        ),
                        Text(
                            '${_controller.athleteGender}  ${_controller.athleteAge}',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Toggles ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TwoStateToggle(
                  label: "Continuing",
                  value: _controller.isContinuing,
                  onChanged: (val) {
                    setState(() {
                      _controller.toggleIsContinuing(val);
                    });
                  },
                ),
                TwoStateToggle(
                  label: "With Pacer",
                  value: _controller.hasPacer,
                  onChanged: (val) {
                    setState(() {
                      _controller.toggleHasPacer(val);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _controller.stationControl('in', 'owens-laptop');
                      _isStationPressed = true;
                      _controller.updateBibNumber('');
                    });
                  },
                  child: Text('${_controller.aidStation} in'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _controller.stationControl('out', 'owens-laptop');
                      _isStationPressed = true;
                      _controller.updateBibNumber('');
                    });
                  },
                  child: Text('${_controller.aidStation} out'),
                ),
              ],
            ),

            const SizedBox(height: 50),
            // Numpad
            Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : NumPad(
                        onNumberPressed: (digit) {
                          setState(() {
                            _controller
                                .updateBibNumber(_controller.bibNumber + digit);
                            _updateAthleteInfo();
                            _isStationPressed = false;
                          });
                        },
                        onBackspace: () {
                          setState(() {
                            if (_controller.bibNumber.isNotEmpty) {
                              _controller.updateBibNumber(_controller.bibNumber
                                  .substring(
                                      0, _controller.bibNumber.length - 1));
                              _updateAthleteInfo();
                              _isStationPressed = false;
                            }
                          });
                        },
                      ))
          ],
        ),
      ),
    );
  }
}
