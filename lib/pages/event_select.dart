import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/dropdown_menu.dart';

class EventSelect extends StatefulWidget {
  const EventSelect({super.key});

  @override
  State<EventSelect> createState() => _EventSelectState();
}

class _EventSelectState extends State<EventSelect> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Event'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CustomDropDownMenu(
              items: const ["Event A", "Event B", "Event C"], 
              hint: 'Select Event',
              onChanged: (value) {
                // TODO: Handle event selection
              },
            ),
           CustomDropDownMenu(
              items: const ["Station A", "Station B", "Station C"], 
              hint: 'Select Aid Station',
              onChanged: (value) {
                // TODO: Handle aid selection
              },
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to the next page or perform an action
              },
              child: const Text('Begin Live Entry'),
            ),
          ],
        ),
      ),
    );
  }
}