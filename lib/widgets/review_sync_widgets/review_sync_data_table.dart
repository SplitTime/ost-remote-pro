import 'package:flutter/material.dart';

class ReviewSyncDataTable extends StatefulWidget {
  final String sortBy;
  final List<Map<String, dynamic>>? data;
  const ReviewSyncDataTable({super.key, required this.sortBy, this.data});

  @override
  State<ReviewSyncDataTable> createState() => _ReviewSyncDataTableState();
}

class _ReviewSyncDataTableState extends State<ReviewSyncDataTable> {
  late List<Map<String, dynamic>> _data;
  late Map<String, List<Map<String, dynamic>>> _groupedData;

  @override
  void initState() {
    super.initState();
    _data = widget.data != null ? List<Map<String, dynamic>>.from(widget.data!) : _fetchData();
    _sortData();
    _groupData();
  }

  @override
  void didUpdateWidget(covariant ReviewSyncDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy) {
      _sortData();
      _groupData();
      setState(() {}); // trigger rebuild
    }
    if (oldWidget.data != widget.data && widget.data != null) {
      _data = List<Map<String, dynamic>>.from(widget.data!);
      _sortData();
      _groupData();
      setState(() {});
    }
  }

  List<Map<String, dynamic>> _fetchData() {
    // TODO: Replace with actual data fetching logic
    return [
      {
        'Bib #': '501',
        'Name': 'John Doe',
        'In/Out': 'In',
        'Time': '01:23:45',
        'Synced': true
      },
      {
        'Bib #': '202',
        'Name': 'Bob Smith',
        'In/Out': 'Out',
        'Time': '02:34:56',
        'Synced': false
      },
      {
        'Bib #': '303',
        'Name': 'Alice Johnson',
        'In/Out': 'In',
        'Time': '03:45:67',
        'Synced': true
      },
    ];
  }

  String _mapSortKey(String sortBy) {
    switch (sortBy) {
      case 'Bib':
      case 'Bib #':
        return 'Bib #';
      case 'Time Displayed':
      case 'Time Entered':
      case 'Time':
        return 'Time';
      case 'Name':
      default:
        return 'Name';
    }
  }

  void _sortData() {
    final key = _mapSortKey(widget.sortBy);
    _data.sort((a, b) => a[key].toString().compareTo(b[key].toString()));
  }

  void _groupData() {
    _groupedData = {};
    for (var row in _data) {
      final aidStation = row['AidStation']?.toString() ?? 'Unknown';
      if (!_groupedData.containsKey(aidStation)) {
        _groupedData[aidStation] = [];
      }
      _groupedData[aidStation]!.add(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: _groupedData.entries.map((entry) {
            final aidStation = entry.key;
            final rows = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: Text(
                    aidStation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(2),
                  },
                  border: const TableBorder(
                    top: BorderSide(width: 0.5, color: Colors.grey),
                    bottom: BorderSide(width: 0.5, color: Colors.grey),
                    horizontalInside: BorderSide(width: 0.5, color: Colors.grey),
                  ),
                  children: rows.map((row) {
                    print('[DATA.MAP] Processing row: ${row}');
                    final textColor = row['Synced'] == true
                        ? Colors.green[700]!
                        : Colors.black;
                    return TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(row['Bib #'].toString(),
                                style: TextStyle(color: textColor))),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(row['Name'].toString(),
                                style: TextStyle(color: textColor))),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(row['In/Out'].toString(),
                                style: TextStyle(color: textColor))),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(row['Time'].toString(),
                                  style: TextStyle(color: textColor))),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
