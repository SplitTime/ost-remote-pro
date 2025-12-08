import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/clock.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/numpad.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';
import 'package:open_split_time_v2/services/network_manager.dart';

import 'package:open_split_time_v2/widgets/live_entry_widgets/edit_bottom_sheet.dart';

class LiveEntryScreen extends StatefulWidget {
  const LiveEntryScreen({super.key});

  @override
  State<LiveEntryScreen> createState() => _LiveEntryScreenState();
}

class _LiveEntryScreenState extends State<LiveEntryScreen> {
  final NetworkManager _networkManager = NetworkManager();
  Map<int, String> _bibNumberToName = {};
  bool _isLoading = true;
  String? _eventName;
  String? _eventSlug;
  String? _aidStation;

  bool _isStationPressed = false;

  String _lastBib = '';
  String _lastAthleteName = '';
  DateTime? _lastEntryTime;

  void _showEditSheet() {

    // Format date and time separately
    final dateStr =
        "${_lastEntryTime!.year}-${_lastEntryTime!.month.toString().padLeft(2, '0')}-${_lastEntryTime!.day.toString().padLeft(2, '0')}";
    final timeStr =
        "${_lastEntryTime!.hour.toString().padLeft(2, '0')}:${_lastEntryTime!.minute.toString().padLeft(2, '0')}:${_lastEntryTime!.second.toString().padLeft(2, '0')}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to grow if needed
      builder: (context) {
        return EditEntryBottomSheet(
          eventName: _eventName ?? 'Event',
          bibNumber: _lastBib,
          athleteName: _lastAthleteName,
          date: dateStr,
          time: timeStr,
          isContinuing: isContinuing, // Assuming current toggle state, or store last state if needed
          hasPacer: hasPacer,
        );
      },
    );
  }

  // We need to format the entered time to the local time zone
  String _formatEnteredTimeLocal() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final oh = offset.inHours.abs().toString().padLeft(2, '0');
    final omin = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final offsetStr = '$sign$oh:$omin';
    return '$y-$mo-$d $hh:$mm:$ss$offsetStr';
  }

  void stationIn() {
    _lastEntryTime = DateTime.now();
    _lastBib = bibNumber;
    _lastAthleteName = athleteName;
    if (_bibNumberToName[int.parse(bibNumber)] == null) {
      // ignore: avoid_print
      print('Bib number not found: $bibNumber');
      return;
    }
    final entered = _formatEnteredTimeLocal();
    final json = {
      'data': [
        {
          'type': 'raw_time',
          'attributes': {
            'source': 'owens-laptop',
            'sub_split_kind': 'in',
            'with_pacer': hasPacer.toString(),
            'entered_time': entered,
            'split_name': _aidStation ?? '',
            'bib_number': bibNumber,
            'stopped_here': (!isContinuing).toString(),
          }
        }
      ]
    };

    print(jsonEncode(json));
  }

  void stationOut() {
    _lastEntryTime = DateTime.now();
    _lastBib = bibNumber;
    _lastAthleteName = athleteName;
    if (_bibNumberToName[int.parse(bibNumber)] == null) {
      // ignore: avoid_print
      print('Bib number not found: $bibNumber');
      return;
    }
    final entered = _formatEnteredTimeLocal();
    final json = {
      'data': [
        {
          'type': 'raw_time',
          'attributes': {
            'source': 'owens-laptop',
            'sub_split_kind': 'out',
            'with_pacer': hasPacer.toString(),
            'entered_time': entered,
            'split_name': _aidStation ?? '',
            'bib_number': bibNumber,
            'stopped_here': (!isContinuing).toString(),
          }
        }
      ]
    };
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
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final eventName = args['event'] as String;
    final eventSlug = args['eventSlug'] as String;
    final aidStationFromArgs = args['aidStation'] as String;

    try {
      final participants =
          await _networkManager.fetchParticipantNames(eventName: eventSlug);
      if (mounted) {
        setState(() {
          _bibNumberToName = participants;
          _isLoading = false;
          _eventName = eventName;
          _eventSlug = eventSlug;
          _aidStation = aidStationFromArgs;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading participants: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // TODO: Use options for writing live entry data
  bool isContinuing = true;
  bool hasPacer = true;

  String bibNumber = '';
  String athleteName = '';
  String athleteOrigin = '';
  String atheleteGender = '';
  String atheleteAge = '';

  void _updateAthleteInfo() {
    if (bibNumber.isNotEmpty) {
      try {
        final bib = int.parse(bibNumber);
        athleteName = _bibNumberToName[bib] ?? '';
        // TODO: Fetch additional athlete info (age, gender, origin) from network manager
        atheleteAge = '(100)';
        atheleteGender = 'Female';
        athleteOrigin = 'Somewhere, ST';
      } catch (e) {
        athleteName = '';
      }
    } else {
      athleteName = '';
      athleteOrigin = '';
      atheleteGender = '';
      atheleteAge = '';
    }
    setState(() {
      _isStationPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the stored aid station (set during _loadParticipants), but fall back to args
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final aidStation = _aidStation ?? args['aidStation'] as String;

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
                      Text(bibNumber,
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
                                : Text(athleteName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),

                            // --- MODIFIED GREEN BOX SECTION ---
                            _isStationPressed
                                ? Material(
                                    // Use Material here for the background color
                                    color: Colors.green,
                                    child: InkWell(
                                      onTap: _showEditSheet,
                                      child: SizedBox(
                                        // Use SizedBox or Container (without color)
                                        height: 35,
                                        width: 200,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.task,
                                                      color: Colors.white),
                                                  Text(_lastBib,
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Container(
                                                color: Colors.tealAccent,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _lastEntryTime != null
                                                          ? "${_lastEntryTime!.hour.toString().padLeft(2, '0')}:${_lastEntryTime!.minute.toString().padLeft(2, '0')}:${_lastEntryTime!.second.toString().padLeft(2, '0')}"
                                                          : "00:00:00",
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    const Text(
                                                      'TAP TO EDIT',
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    athleteOrigin,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.blue),
                                  ),
                            // ----------------------------------
                          ],
                        ),
                        Text('$atheleteGender$atheleteAge',
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
                  value: isContinuing,
                  onChanged: (val) {
                    setState(() {
                      isContinuing = val;
                    });
                  },
                ),
                TwoStateToggle(
                  label: "With Pacer",
                  value: hasPacer,
                  onChanged: (val) {
                    setState(() {
                      hasPacer = val;
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
                      stationIn();
                      _isStationPressed = true;
                      bibNumber = '';
                    });
                  },
                  child: Text('$aidStation in'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      stationOut();
                      _isStationPressed = true;
                      bibNumber = '';
                    });
                  },
                  child: Text('$aidStation out'),
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
                            bibNumber += digit;
                            _updateAthleteInfo();
                            _isStationPressed = false;
                          });
                        },
                        onBackspace: () {
                          setState(() {
                            if (bibNumber.isNotEmpty) {
                              bibNumber =
                                  bibNumber.substring(0, bibNumber.length - 1);
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
