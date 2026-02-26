import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:open_split_time_v2/widgets/page_router.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/services/crosscheck/cross_check_service.dart';

class CrossCheckPage extends StatefulWidget {
  const CrossCheckPage({super.key});

  @override
  State<CrossCheckPage> createState() => _CrossCheckPageState();
}

class _CrossCheckPageState extends State<CrossCheckPage> {
  final CrossCheckService _service =
      CrossCheckService(network: NetworkManager());

  bool _bulkSelect = false;
  Set<int> _selected = {};
  CrossCheckStatus? _filter; // null => show all
  bool _loading = true;

  String _eventSlug = 'demo-event';
  String _splitName = 'Demo Station';

  // NEW: bibMap passed from LiveEntry (or any caller)
  Map<int, String>? _bibMap;

  CrossCheckViewModel? _vm;
  bool _didInit = false;

  Color _statusColor(CrossCheckStatus s) {
    switch (s) {
      case CrossCheckStatus.recorded:
        return Colors.green;
      case CrossCheckStatus.stopped:
        return Colors.red;
      case CrossCheckStatus.notExpected:
        return const Color(0xFF505050); // Dark gray like iOS
      case CrossCheckStatus.expected:
        return Colors.blue;
    }
  }

  String _statusLabel(CrossCheckStatus s) {
    switch (s) {
      case CrossCheckStatus.recorded:
        return 'Recorded';
      case CrossCheckStatus.stopped:
        return 'Dropped Here';
      case CrossCheckStatus.notExpected:
        return 'Not Expected';
      case CrossCheckStatus.expected:
        return 'Expected';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _eventSlug = (args['eventSlug'] ?? _eventSlug).toString();
      _splitName =
          (args['splitName'] ?? args['aidStation'] ?? _splitName).toString();

      final bm = args['bibMap'];
      if (bm is Map<int, String>) {
        _bibMap = bm;
      } else if (bm is Map) {
        // Handle Map<dynamic, dynamic> safely
        final converted = <int, String>{};
        bm.forEach((k, v) {
          final bib = int.tryParse(k.toString());
          if (bib != null) {
            converted[bib] = v.toString();
          }
        });
        if (converted.isNotEmpty) _bibMap = converted;
      }
    }

    _load(initial: true);
  }

  Future<void> _load({required bool initial}) async {
    if (initial) {
      setState(() {
        _loading = true;
      });
    }

    // If we don't have a bibMap, fetch participants from the server
    if (_bibMap == null || _bibMap!.isEmpty) {
      try {
        final participants = await _service.network.fetchParticipantNames(
          eventName: _eventSlug,
        );
        if (participants.isNotEmpty) {
          _bibMap = participants.map(
            (bib, info) => MapEntry(bib, info['fullName'] ?? ''),
          );
        }
      } catch (e) {
        // Silently fail - we'll still show any local entries
        developer.log('CrossCheck: Failed to fetch participants: $e', name: 'CrossCheckPage');
      }
    }

    // optional server overwrite if online
    await _service.refreshFlagsFromServer(
      eventSlug: _eventSlug,
      splitName: _splitName,
    );

    final vm = await _service.build(
      eventSlug: _eventSlug,
      splitName: _splitName,
      selectedBibs: _selected,
      bibMap: _bibMap,
    );

    if (!mounted) return;
    setState(() {
      _vm = vm;
      _loading = false;
    });
  }

  void _toggleSelect(CrossCheckItem item) {
    if (!_bulkSelect) return;
    if (!item.isSelectable) return;

    setState(() {
      if (_selected.contains(item.bib)) {
        _selected.remove(item.bib);
      } else {
        _selected.add(item.bib);
      }
    });
  }

  List<CrossCheckItem> _filteredItems(List<CrossCheckItem> items) {
    if (_filter == null) return items;
    return items.where((i) => i.status == _filter).toList();
  }

  // ---- Bottom bar widgets ----
  Widget _bottomTab({
    required String label,
    required int count,
    required CrossCheckStatus status,
    required Color color,
  }) {
    final selected = _filter == status;

    return InkWell(
      onTap: () => setState(() => _filter = status),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showAllTab({required int count}) {
    final selected = _filter == null;

    return InkWell(
      onTap: () => setState(() => _filter = null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Show\nAll',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade600, width: 2),
                color: selected
                    ? Colors.grey.shade600.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markSelectedExpected() async {
    await _service.setSelectedToExpected(
      eventSlug: _eventSlug,
      splitName: _splitName,
      selectedBibs: _selected,
    );
    setState(() => _selected = {});
    await _load(initial: false);
  }

  Future<void> _markSelectedNotExpected() async {
    await _service.setSelectedToNotExpected(
      eventSlug: _eventSlug,
      splitName: _splitName,
      selectedBibs: _selected,
    );
    setState(() => _selected = {});
    await _load(initial: false);
  }

  void _showRunnerDetails(CrossCheckItem item) {
    final runnerName = _bibMap?[item.bib] ?? 'Unknown';
    final bg = _statusColor(item.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button row
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Runner info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Runner name
                    Expanded(
                      child: Text(
                        runnerName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Mini bib tile
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item.bib}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusLabel(item.status),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;

    return Scaffold(
      endDrawer: const PageRouterDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: TextButton(
          onPressed: () {
            setState(() {
              if (_bulkSelect) {
                _bulkSelect = false;
                _selected = {};
              } else {
                _bulkSelect = true;
              }
            });
          },
          child: Text(
            _bulkSelect ? 'Cancel' : 'Bulk Select',
            style: TextStyle(
              color: _bulkSelect ? Colors.red : Colors.blue,
              fontSize: 13,
            ),
          ),
        ),
        leadingWidth: 100,
        centerTitle: true,
        title: const Text(
          'Cross Check',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => TextButton.icon(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu, color: Colors.blue),
              label: const Text(
                'Menu',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),

      // Bottom filter bar
      bottomNavigationBar: vm == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bottomTab(
                      label: 'Recorded',
                      count: vm.counts[CrossCheckStatus.recorded] ?? 0,
                      status: CrossCheckStatus.recorded,
                      color: Colors.green,
                    ),
                    _bottomTab(
                      label: 'Dropped\nHere',
                      count: vm.counts[CrossCheckStatus.stopped] ?? 0,
                      status: CrossCheckStatus.stopped,
                      color: Colors.red,
                    ),
                    _bottomTab(
                      label: 'Expected',
                      count: vm.counts[CrossCheckStatus.expected] ?? 0,
                      status: CrossCheckStatus.expected,
                      color: Colors.blue,
                    ),
                    _bottomTab(
                      label: 'Not\nExpected',
                      count: vm.counts[CrossCheckStatus.notExpected] ?? 0,
                      status: CrossCheckStatus.notExpected,
                      color: Colors.black87,
                    ),
                    _showAllTab(count: vm.items.length),
                  ],
                ),
              ),
            ),

      body: _loading || vm == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(initial: false),
              child: Column(
                children: [
                  // Header like iOS
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                    child: Column(
                      children: [
                        const Text(
                          'Your Location:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _splitName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(thickness: 2),
                      ],
                    ),
                  ),

                  // Grid of bib tiles
                  Expanded(
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: _filteredItems(vm.items).length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems(vm.items)[index];
                        final bg = _statusColor(item.status);

                        return GestureDetector(
                          onTap: () {
                            if (_bulkSelect) {
                              _toggleSelect(item);
                            } else {
                              _showRunnerDetails(item);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: (_bulkSelect && _selected.contains(item.bib))
                                      ? bg.withValues(alpha: 0.5)
                                      : bg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item.bib}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _statusLabel(item.status),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_bulkSelect && _selected.contains(item.bib))
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Return button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Return To Live Entry'),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bulk buttons
                  if (_bulkSelect)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _selected.isEmpty
                                  ? null
                                  : _markSelectedExpected,
                              child: const Text('Expected'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _selected.isEmpty
                                  ? null
                                  : _markSelectedNotExpected,
                              child: const Text('Not Expected'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
