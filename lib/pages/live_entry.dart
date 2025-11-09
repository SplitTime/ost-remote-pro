import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/app_menu_drawer.dart';
import 'package:open_split_time_v2/widgets/two_state_toggle.dart';

class LiveEntryScreen extends StatefulWidget {
  const LiveEntryScreen({super.key});

  @override
  State<LiveEntryScreen> createState() => _LiveEntryScreenState();
}


class _LiveEntryScreenState extends State<LiveEntryScreen> {
  void stationIn() {
    // TODO: Implement station in logic
  }

  void stationOut() {
    // TODO: Implement station out logic
  }

  // TODO: Use options for writing live entry data
  bool isContinuing = true;
  bool hasPacer = true;

  // TODO: Update with real athlete data
  String bibNumber = '';
  String athleteName = 'Demo Athlete';

  @override
  Widget build(BuildContext context) {
    // Extract the arguments passed from the navigation
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Access event and aidStation from args
    // TODO: Use event and aidStation as for writing live entry data
    final event = args['event'];
    final aidStation = args['aidStation'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Entry'),
      ),
      endDrawer: const AppMenuDrawer(),
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
          ],
        ),
      ),
    );
  }
}