import 'package:flutter/material.dart';

class ReviewSyncDataTable extends StatefulWidget {
  final String sortBy;
  const ReviewSyncDataTable({super.key, required this.sortBy});

  @override
  State<ReviewSyncDataTable> createState() => _ReviewSyncDataTableState();
}

class _ReviewSyncDataTableState extends State<ReviewSyncDataTable> {
  late List<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _data = _fetchData();
    _sortData();
  }

  @override
  void didUpdateWidget(covariant ReviewSyncDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy) {
      _sortData();
      setState(() {}); // trigger rebuild
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

  void _sortData() {
    _data.sort((a, b) =>
        a[widget.sortBy].toString().compareTo(b[widget.sortBy].toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Table(
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
          children: _data.map((row) {
            final textColor =
                row['Synced'] == true ? Colors.green[700]! : Colors.black;
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
      ),
    );
  }
}
