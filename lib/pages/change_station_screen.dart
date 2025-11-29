import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/network_manager.dart';

class ChangeStationScreen extends StatefulWidget {
  const ChangeStationScreen({super.key});

  @override
  State<ChangeStationScreen> createState() => _ChangeStationScreenState();
}

class _ChangeStationScreenState extends State<ChangeStationScreen> {
  String? selectedStation;
  String? eventName;
  List<String> stationList = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEventAndStations();
  }

  Future<void> _loadEventAndStations() async {
    final prefs = await SharedPreferences.getInstance();

    eventName = prefs.getString("eventName");
    selectedStation = prefs.getString("selectedAid");

    final allEventsMap = await NetworkManager().fetchEventDetails();

    // Match event safely
    String? matchedEvent;
    if (eventName != null) {
      for (final key in allEventsMap.keys) {
        if (key.toLowerCase().trim() == eventName!.toLowerCase().trim()) {
          matchedEvent = key;
          break;
        }
      }
    }

    matchedEvent ??= allEventsMap.keys.isNotEmpty ? allEventsMap.keys.first : null;

    if (matchedEvent != null) {
      stationList = allEventsMap[matchedEvent] ?? [];
    }

    if (!stationList.contains(selectedStation)) {
      selectedStation = null;
    }

    setState(() {
      eventName = matchedEvent;
      loading = false;
    });
  }

  Future<void> _goToLiveEntry() async {
  if (selectedStation == null) return;

  final prefs = await SharedPreferences.getInstance();
  prefs.setString("selectedAid", selectedStation!);

  if (!mounted) return;

  Navigator.pop(context);

  Navigator.pushNamed(
    context,
    '/liveEntry',
    arguments: {
      'event': eventName ?? 'Unknown Event',
      'aidStation': selectedStation!,
      'eventSlug': (eventName ?? 'unknown-event').toLowerCase().replaceAll(" ", "-"),
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  // MAIN CONTENT
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        Image.asset("assets/images/ost_logo.jpg", height: 120),

                        const SizedBox(height: 15),

                        const Text(
                          "OST Remote",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "(Please Logout to change events)",
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),

                        const SizedBox(height: 30),

                        Text(
                          eventName ?? "Event Not Found",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 20),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Select Aid Station:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedStation,
                          items: stationList
                              .map(
                                (station) => DropdownMenuItem<String>(
                                  value: station,
                                  child: Text(station),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStation = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),

                        const Spacer(),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _goToLiveEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              "Live Entry",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  Positioned(
                    right: 10,
                    top: 10,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.lightGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
