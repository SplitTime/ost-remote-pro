import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/dropdown_menu.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/widgets/review_sync_widgets/sync_export_footer.dart';
import 'package:open_split_time_v2/widgets/review_sync_widgets/review_sync_data_table.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';
import 'dart:developer' as developer;

class ReviewSyncPage extends StatefulWidget {
  const ReviewSyncPage({super.key});

  @override
  State<ReviewSyncPage> createState() => _ReviewSyncPageState();
}

class _ReviewSyncPageState extends State<ReviewSyncPage> {
  final NetworkManager _networkManager = NetworkManager();
  // TODO: Use PreferencesService instead of direct SharedPreferences access
  final PreferencesService _prefs = PreferencesService();
  String? sortBy = "Name"; // Default sort by Name
  String? _eventSlug;
  List<Map<String, dynamic>> _tableRows = [];

  final List<String> sortByItems = [
    "Name",
    "Time Displayed",
    "Time Entered",
    "Bib #"
  ];

  // Local queued entries loaded from SharedPreferences ('raw_times')
  List<Map<String, dynamic>> _localEntries = [];
  Map<int, Map<String, String>> _bibToName = {};

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _eventSlug = _prefs.selectedEventSlug;
    developer.log('Selected event slug: $_eventSlug',
        name: 'ReviewSyncPage');
    if (mounted) {
      setState(() {});
      await _loadLocalEntries();
    }
  }

  Future<void> _loadLocalEntries() async {
    _eventSlug = _prefs.selectedEventSlug;
    // developer.log('Loading local entries for event slug: $_eventSlug',
    //     name: 'ReviewSyncPage');
    if (_eventSlug == null) {
      if (mounted) setState(() => _localEntries = []);
      return;
    }

    final storedJson = _prefs.rawTimes;
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
        final participants =
            await _networkManager.fetchParticipantNames(eventName: _eventSlug!);
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

  Future<Map<String, dynamic>> buildBatchPayload(List entriesToProcess) async {
    for (final entry in entriesToProcess) {
      // Add logic to strip the meta field and any other unnecessary fields
      entry.remove('meta');
    }
    return {
      "data": entriesToProcess,
    };
  }

  Future<void> _updateLocalEntries() async {
    if (_eventSlug == null) return;

    try {
      final storedJson = _prefs.rawTimes;
      if (storedJson == null || storedJson.isEmpty) return;

      final List<dynamic> entries = json.decode(storedJson);
      bool updated = false;

      // Mark all entries as synced
      for (var entry in entries) {
        if (entry is Map && entry['meta']?['synced'] != true) {
          entry['meta'] = {'synced': true};
          updated = true;
        }
      }

      if (updated) {
        _prefs.rawTimes = json.encode(entries);
        if (mounted) {
          await _loadLocalEntries(); // Refresh the UI
        }
      }
    } catch (e) {
      developer.log('Error updating local entries: $e', name: 'ReviewSyncPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating local entries: $e')),
        );
      }
    }
  }

  void onSyncPressed() async {
    if (_eventSlug == null || _eventSlug!.isEmpty) {
      developer.log('No event slug selected; cannot sync',
          name: 'ReviewSyncPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No event selected!')),
        );
      }
      return;
    }

    try {
      final storedJson = _prefs.rawTimes;
      final List<dynamic> entriesToProcess = [];

      if (storedJson == null || storedJson.isEmpty) {
        developer.log('No local data to sync', name: 'ReviewSyncPage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to sync!')),
          );
        }
        return;
      }

      // Parse and filter entries
      final List<dynamic> allEntries = json.decode(storedJson);
      for (var entry in allEntries) {
        if (entry is Map && entry['meta']?['synced'] != true) {
          entriesToProcess
              .add(Map<String, dynamic>.from(entry)); // Create a copy
        }
      }

      if (entriesToProcess.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new entries to sync!')),
          );
        }
        return;
      }

      // Show loading indicator
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        const SnackBar(
            content: Text('Syncing entries...'),
            duration: Duration(seconds: 5)),
      );

      // Process the sync
      final entriesToSync = await buildBatchPayload(entriesToProcess);
      print('Entries to sync: ${entriesToSync.length}');
      print(jsonEncode(entriesToSync));
      final success =
          await _networkManager.syncEntries(_eventSlug!, entriesToSync);

      developer.log('Sync completed, success: $success',
          name: 'ReviewSyncPage');

      if (success && mounted) {
        await _updateLocalEntries();
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully synced ${entriesToProcess.length} entries!')),
        );
      } else if (mounted) {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          const SnackBar(content: Text('Sync failed. Please try again.')),
        );
      }
    } catch (e) {
      developer.log('Sync failed: $e', name: 'ReviewSyncPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during sync: ${e.toString()}')),
        );
      }
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
                  Text(
                    '${_prefs.selectedEvent}',
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
                _tableRows = _localEntries.map((item) {
                  final attrs = (item['attributes'] is Map) ? 
                  Map<String, dynamic>.from(item['attributes']) : <String, dynamic>{};
                  final meta = (item['meta'] is Map) ?
                  Map<String, dynamic>.from(item['meta']) : <String, dynamic>{};

                  final aidStation = attrs['split_name']?.toString() ?? '';
                  final bibStr = attrs['bib_number']?.toString() ?? '';
                  final bib = int.tryParse(bibStr) ?? -1;
                  final synced = meta['synced'];
                  final name = (bib != -1 && _bibToName.containsKey(bib))
                      ? _bibToName[bib]!['fullName']
                      : (attrs['fullName']?.toString() ?? '');
                  return {
                    'AidStation': aidStation,
                    'Bib #': bibStr,
                    'Name': name ?? '',
                    'In/Out': attrs['sub_split_kind']?.toString() ?? '',
                    'Time': attrs['entered_time']?.toString() ?? '',
                    'Synced': synced,
                  };
                }).toList();
                return ReviewSyncDataTable(sortBy: sortBy!, data: _tableRows);
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
