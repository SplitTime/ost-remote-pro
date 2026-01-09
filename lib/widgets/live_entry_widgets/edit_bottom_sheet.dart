import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';

class EditEntryBottomSheet extends StatefulWidget {
  final String eventName;
  final String bibNumber;
  final String athleteName;
  final String date;
  final String time;
  final bool isContinuing;
  final bool hasPacer;

  const EditEntryBottomSheet({
    super.key,
    required this.eventName,
    required this.bibNumber,
    required this.athleteName,
    required this.date,
    required this.time,
    required this.isContinuing,
    required this.hasPacer,
  });

  @override
  State<EditEntryBottomSheet> createState() => _EditEntryBottomSheetState();
}

class _EditEntryBottomSheetState extends State<EditEntryBottomSheet> {
  late TextEditingController _bibController;
  late DateTime _selectedDate;
  // Using Duration for Time to support Hours, Minutes, AND Seconds
  late Duration _selectedDuration;

  bool isContinuing = false;
  bool hasPacer = false;

  @override
  void initState() {
    super.initState();
    isContinuing = widget.isContinuing;
    hasPacer = widget.hasPacer;
    _bibController = TextEditingController(text: widget.bibNumber);

    // 1. Parse Date
    try {
      _selectedDate = DateTime.parse(widget.date);
    } catch (e) {
      _selectedDate = DateTime.now();
    }

    // 2. Parse Time (HH:MM:SS) into Duration
    try {
      final parts = widget.time.split(':');
      _selectedDuration = Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      );
    } catch (e) {
      final now = DateTime.now();
      _selectedDuration = Duration(
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
      );
    }


  }

  @override
  void dispose() {
    _bibController.dispose();
    super.dispose();
  }

  // --- Date Picker (Cupertino) ---
  void _pickDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              // Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              // Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2100),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Time Picker (Cupertino with Seconds) ---
  void _pickTime() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              // Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              // Picker
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms, // Hours, Mins, Secs
                  initialTimerDuration: _selectedDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    setState(() {
                      _selectedDuration = newDuration;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper to format Date
  String get _formattedDate {
    return "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
  }

  // Helper to format Time (Duration -> HH:MM:SS)
  String get _formattedTime {
    final h = _selectedDuration.inHours.toString().padLeft(2, '0');
    final m = (_selectedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_selectedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.eventName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // --- Editable Bib Number ---
            Row(
              children: [
                const Text(
                  'Bib Number: ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _bibController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildInfoRow('Bib Found:', widget.athleteName),

            // --- Editable Date (Cupertino) ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Date: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formattedDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Editable Time (Cupertino with Seconds) ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Time: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formattedTime,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Two State Toggles ---
            // TODO: Wire these up to actual state variables
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

            const SizedBox(height: 20),

            // --- Action Buttons ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Delete Logic
                      print("Delete requested for bib ${_bibController.text}");
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Update Logic
                      print("Update requested:");
                      print("Bib: ${_bibController.text}");
                      print("Date: $_formattedDate");
                      print("Time: $_formattedTime");
                      Navigator.pop(context);
                    },
                    child: const Text('Update'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}