import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/dropdown_menu.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'dart:developer' as developer;

class ReviewSyncPage extends StatefulWidget {
  const ReviewSyncPage({super.key});

  @override
  State<ReviewSyncPage> createState() => _ReviewSyncPageState();
}

class _ReviewSyncPageState extends State<ReviewSyncPage> {
  String? sortBy = "Name"; // Default sort by Name
  final List<String> sortByItems = [
    "Name",
    "Time Displayed",
    "Time Entered",
    "Bib #"
  ];

  void _onSortByChanged(String? newValue) {
    setState(() {
      sortBy = newValue;
    });
    developer.log('Sort by changed to $newValue');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const PageRouterDrawer(),
      appBar: AppBar(
        title: const Text('Review/Sync'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sort By:'),
                  CustomDropDownMenu(
                    items: sortByItems,
                    hint: "Sort By",
                    initialValue: sortBy,
                    onChanged: _onSortByChanged,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TODO: Replace with actual aidstation
                  Text(
                    'aidStation Entries:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Aa = Synced',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1), // Bib #
                        1: FlexColumnWidth(3), // Name
                        2: FlexColumnWidth(1), // In/Out
                        3: FlexColumnWidth(2), // Time
                      },
                      border: const TableBorder(
                        top: BorderSide(width: 0.5, color: Colors.grey),
                        bottom: BorderSide(width: 0.5, color: Colors.grey),
                        horizontalInside:
                            BorderSide(width: 0.5, color: Colors.grey),
                      ),
                      children: [
                        TableRow(
                          children: const [
                            Padding(
                                padding: EdgeInsets.all(8), child: Text('123')),
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Sarah')),
                            Padding(
                                padding: EdgeInsets.all(8), child: Text('In')),
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('17:30:12'),
                                )),
                          ],
                        ),
                        TableRow(
                          children: const [
                            Padding(
                                padding: EdgeInsets.all(8), child: Text('456')),
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Janine')),
                            Padding(
                                padding: EdgeInsets.all(8), child: Text('Out')),
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('12:30:45'),
                                )),
                          ],
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
          height: 50,
          child: Row(
            children: [
              Expanded(
                  flex: 10,
                  child: GestureDetector(
                      onTap: () {
                        // TODO: Implement sync functionality
                        developer.log('Sync button tapped',
                            name: 'ReviewSyncPage');
                      },
                      child: Container(
                        color: Colors.green[700],
                        child: Center(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sync',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const Icon(
                              Icons.sync,
                              color: Colors.white,
                            )
                          ],
                        )),
                      ))),
              Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      developer.log('Export button tapped',
                          name: 'ReviewSyncPage');
                    },
                    child: Container(
                      color: Colors.blue[300],
                      child: const Center(
                        child: Icon(
                          Icons.ios_share,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ))
            ],
          )),
    );
  }
}
