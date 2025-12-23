import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/dropdown_menu.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/widgets/review_sync_widgets/sync_export_footer.dart';
import 'package:open_split_time_v2/widgets/review_sync_widgets/review_sync_data_table.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ReviewSyncPage extends StatefulWidget {
  const ReviewSyncPage({super.key});

  @override
  State<ReviewSyncPage> createState() => _ReviewSyncPageState();
}

class _ReviewSyncPageState extends State<ReviewSyncPage> {
  final NetworkManager _networkManager = NetworkManager();
  String? sortBy = "Name"; // Default sort by Name
  late SharedPreferences prefs;
  String? _eventSlug;

  final List<String> sortByItems = [
    "Name",
    "Time Displayed",
    "Time Entered",
    "Bib #"
  ];

  // Local queued entries loaded from SharedPreferences ('raw_times')
  List<Map<String, dynamic>> _localEntries = [];
  Map<int, String> _bibToName = {};

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _eventSlug = prefs.getString('selectedEventSlug');
    if (mounted) {
      setState(() {});
      await _loadLocalEntries();
    }
  }

  Future<void> _loadLocalEntries() async {
    if (_eventSlug == null) {
      if (mounted) setState(() => _localEntries = []);
      return;
    }
    
    final storedJson = prefs.getString('${_eventSlug}_raw_times');
    if (storedJson == null || storedJson.isEmpty) {
      if (mounted) setState(() => _localEntries = []);
      return;
    }

    try {
      final decoded = jsonDecode(storedJson) as List<dynamic>;
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      if (mounted) setState(() => _localEntries = list);
    } catch (e) {
      if (mounted) setState(() => _localEntries = []);
    }
    // Also attempt to load participant names for the selected event (to show names)
    try {
      if (_eventSlug != null && _eventSlug!.isNotEmpty) {
        final participants = await _networkManager.fetchParticipantNames(eventName: _eventSlug!);
        if (mounted) setState(() => _bibToName = participants);
      }
    } catch (e) {
      if (mounted) setState(() => _bibToName = {});
    }
  }

  void _onSortByChanged(String? newValue) {
    setState(() {
      sortBy = newValue;
    });
    developer.log('Sort by changed to $newValue');
  }

  Future<Map<String, dynamic>> buildBatchPayload() async {
    if (_eventSlug == null) return {};
    final storedJson = prefs.getString('${_eventSlug}_raw_times');

    if (storedJson == null) {
      return {};
    }

    final List<dynamic> entries = jsonDecode(storedJson);

    return {
      "data": entries,
      "data_format": "jsonapi_batch",
      "limited_response": "true"
    };
  }

  void onSyncPressed() async {
    // Build payload and read selected event slug from prefs
    if (_eventSlug == null || _eventSlug!.isEmpty) {
      developer.log('No event slug selected; cannot sync', name: 'ReviewSyncPage');
      return;
    }

    try {
      final entriesToSync = buildBatchPayload();
      await _networkManager.syncEntries(_eventSlug!, entriesToSync);
      developer.log('Sync button pressed', name: 'ReviewSyncPage');
    } catch (e) {
      developer.log('Sync failed: $e', name: 'ReviewSyncPage');
    }
  }

  void onExportPressed() {
    // TODO: Implement export functionality
    developer.log('Export button pressed', name: 'ReviewSyncPage');
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
                    value: sortBy,
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
              // Build rows for the data table from local queued entries
              Builder(builder: (context) {
                final tableRows = _localEntries.map((item) {
                  final attrs = (item['attributes'] is Map) ? Map<String, dynamic>.from(item['attributes']) : <String, dynamic>{};
                  final bibStr = attrs['bib_number']?.toString() ?? '';
                  final bib = int.tryParse(bibStr ?? '') ?? -1;
                  final name = (bib != -1 && _bibToName.containsKey(bib))
                      ? _bibToName[bib]
                      : (attrs['full_name']?.toString() ?? '');
                  return {
                    'Bib #': bibStr,
                    'Name': name ?? '',
                    'In/Out': attrs['sub_split_kind']?.toString() ?? '',
                    'Time': attrs['entered_time']?.toString() ?? '',
                    'Synced': attrs['synced'] == true,
                  };
                }).toList();

                return ReviewSyncDataTable(sortBy: sortBy!, data: tableRows);
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SyncExportFooter(
        onSyncPressed: onSyncPressed,
        onExportPressed: onExportPressed,
      ),
    );
  }
}
