import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/app_menu_drawer.dart';

class LiveEntryScreen extends StatefulWidget {
  const LiveEntryScreen({super.key});

  @override
  State<LiveEntryScreen> createState() => _LiveEntryScreenState();
}

class _LiveEntryScreenState extends State<LiveEntryScreen> {
  @override
  Widget build(BuildContext context) {
    // Extract the arguments passed from the navigation
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final event = args['event'];
    final aidStation = args['aidStation'];

    String bibNumber = '';
    String athleteName = 'Demo Athlete';
    bool isContinuing = true;
    bool hasPacer = false;

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
          ],
        ),
      ),
    );
  }
}