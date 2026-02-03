import 'package:flutter/material.dart';

class StationStatusDisplay extends StatelessWidget {
  final bool isStationPressed;
  final String atheleteOrigin;
  final VoidCallback showEditSheet;
  final String lastBib;
  final DateTime? lastEntryTime;

  const StationStatusDisplay({
    super.key,
    required this.isStationPressed,
    required this.atheleteOrigin,
    required this.showEditSheet,
    required this.lastBib,
    this.lastEntryTime,
  });

  @override
  Widget build(BuildContext context) {
    if (!isStationPressed) {
      return Text(
        atheleteOrigin,
        style: TextStyle(fontSize: 16, color: Colors.blue),
      );
    } else {
      return Material(
        // Use Material here for the background color
        color: Colors.green,
        child: InkWell(
          onTap: showEditSheet,
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
                      const Icon(Icons.task, color: Colors.white),
                      Text(lastBib,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.tealAccent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lastEntryTime != null
                              ? "${lastEntryTime!.hour.toString().padLeft(2, '0')}:${lastEntryTime!.minute.toString().padLeft(2, '0')}:${lastEntryTime!.second.toString().padLeft(2, '0')}"
                              : "00:00:00",
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'TAP TO EDIT',
                          style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
