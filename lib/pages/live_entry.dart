import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/clock.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/numpad.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';
import 'package:open_split_time_v2/services/network_manager.dart';

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

    setState(() {
      _isStationPressed = true;
    });

    print(jsonEncode(json));
  }

  void stationOut() {
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

    setState(() {
      _isStationPressed = true;
    });

    print(jsonEncode(json));
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
                Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bibNumber,
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w900),
                        ),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              height: 20,
                              color: Colors.lightBlue,
                              child: const Center(
                                child: Text(
                                  'Time of day',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            )),
                        Center(child: ClockWidget()),
                      ],
                    )),
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
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(
                                          athleteName,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                  _isStationPressed
                                      ? Container(
                                          // Green Box when 'IN' is pressed
                                          height:
                                              20, // Set a height for visibility
                                          width:
                                              100, // Set a width for visibility
                                          color: Colors.green,
                                        )
                                      : Text(
                                          // Original Text when 'IN' is NOT pressed
                                          athleteOrigin,
                                          style: const TextStyle(
                                              fontSize: 16, color: Colors.blue),
                                        ),
                                ],
                              ),
                              Text('$atheleteGender$atheleteAge',
                                  style: const TextStyle(fontSize: 16)),
                            ]))),
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
                  onPressed: stationIn,
                  child: Text('$aidStation in'),
                ),
                ElevatedButton(
                  onPressed: stationOut,
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
                          });
                        },
                        onBackspace: () {
                          setState(() {
                            if (bibNumber.isNotEmpty) {
                              bibNumber =
                                  bibNumber.substring(0, bibNumber.length - 1);
                              _updateAthleteInfo();
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
