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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Entry'),
      ),
      endDrawer: const AppMenuDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Event: ${event.toString()}'),
            const SizedBox(height: 16),
            Text('Aid Station: ${aidStation.toString()}'),
          ],
        ),
      ),
    );
  }
}