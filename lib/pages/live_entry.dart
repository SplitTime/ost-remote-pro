import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/numpad.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> appendEntry(newEntryJson) async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // Get existing list OR create a new empty list
    final storedJson = prefs.getString('${_eventSlug}_raw_times');
    List<dynamic> list = storedJson != null ? jsonDecode(storedJson) : [];

    // Add the new entry
    list.add(newEntryJson);

    // Save updated list
    await prefs.setString('${_eventSlug}_raw_times', jsonEncode(list));
  }

  void stationIn() async {
    if(_bibNumberToName[int.parse(bibNumber)] == null) {
      // ignore: avoid_print
      print('Bib number not found: $bibNumber');
      return;
    }
    final entered = _formatEnteredTimeLocal();
    final json = {
      'type': 'raw_time',
      'attributes': {
        'source': 'owens-laptop',
        'sub_split_kind': 'in',
        'with_pacer': hasPacer.toString(),
        'entered_time': entered,
        'split_name': _aidStation ?? '',
        'bib_number': bibNumber,
        'stopped_here': (!isContinuing).toString(),
      },
      'meta': {
        'synced': false
      }
    };
    print(json);
    await appendEntry(json);
  }

  void stationOut() async {
    if(_bibNumberToName[int.parse(bibNumber)] == null) {
      // ignore: avoid_print
      print('Bib number not found: $bibNumber');
      return;
    }
    final entered = _formatEnteredTimeLocal();
    final json = {
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
    };
    await appendEntry(json);
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
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final eventName = args['event'] as String;
    final eventSlug = args['eventSlug'] as String;
    final aidStationFromArgs = args['aidStation'] as String;

    
    try {
      final participants = await _networkManager.fetchParticipantNames(eventName: eventSlug);
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

  // Use options for writing live entry data
  bool isContinuing = true;
  bool hasPacer = true;

  String bibNumber = '';
  String athleteName = '';

  void _updateAthleteName() {
    if (bibNumber.isNotEmpty) {
      try {
        final bib = int.parse(bibNumber);
        athleteName = _bibNumberToName[bib] ?? '';
      } catch (e) {
        athleteName = '';
      }
    } else {
      athleteName = '';
    }
  }

  @override
  Widget build(BuildContext context) {
  // Prefer the stored aid station (set during _loadParticipants), but fall back to args
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  final aidStation = _aidStation ?? args['aidStation'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Entry'),
      ),
      endDrawer: const PageRouterDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Top: Bib number and name ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bib: $bibNumber',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    athleteName,
                    style: const TextStyle(fontSize: 20),
                  ),
              ],
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),
            
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

            const SizedBox(height: 100),
            // Numpad
            Expanded(
              child: 
                _isLoading
                ? const Center(child: CircularProgressIndicator())
                : NumPad(
                  onNumberPressed: (digit) {
                    setState(() {
                      bibNumber += digit;
                      _updateAthleteName();
                    });
                  },
                  onBackspace: () {
                    setState(() {
                      if (bibNumber.isNotEmpty) {
                        bibNumber = bibNumber.substring(0, bibNumber.length - 1);
                        _updateAthleteName();
                      }
                    });
                  },
                ) 
              )
          ],
        ),
      ),
    );
  }
}