// lib/screens/live_timing_screen.dart
//
// Real-time display using WebSocket

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/live_timing_provider.dart';
import '../models/split_time.dart';

class LiveTimingScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  
  const LiveTimingScreen({
    required this.eventId,
    required this.eventName,
    super.key,
  });
  
  @override
  State<LiveTimingScreen> createState() => _LiveTimingScreenState();
}

class _LiveTimingScreenState extends State<LiveTimingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveTimingProvider>().startLiveTiming(widget.eventId);
    });
  }
  
  @override
  void dispose() {
    context.read<LiveTimingProvider>().stopLiveTiming();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.eventName, style: TextStyle(fontSize: 16)),
            Consumer<LiveTimingProvider>(
              builder: (context, provider, _) => Text(
                provider.isConnected ? '🟢 Live' : '🔴 Disconnected',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<LiveTimingProvider>(
            builder: (context, provider, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total: ${provider.totalReads}', 
                       style: TextStyle(fontSize: 12)),
                  Text('RFID: ${provider.rfidReads}', 
                       style: TextStyle(fontSize: 10, color: Colors.green)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<LiveTimingProvider>(
        builder: (context, provider, _) {
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                ],
              ),
            );
          }
          
          if (provider.splitTimes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Waiting for timing data...'),
                  SizedBox(height: 8),
                  Text(
                    'Connected to live feed',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: provider.splitTimes.length,
            itemBuilder: (context, index) {
              final splitTime = provider.splitTimes[index];
              return _SplitTimeCard(
                splitTime: splitTime,
                isNew: index == 0, // Highlight newest
              );
            },
          );
        },
      ),
    );
  }
}

class _SplitTimeCard extends StatelessWidget {
  final SplitTime splitTime;
  final bool isNew;
  
  const _SplitTimeCard({required this.splitTime, this.isNew = false});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isNew ? Colors.green[50] : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: splitTime.isRfid ? Colors.green : Colors.blue,
              child: Text(
                splitTime.bibNumber,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (splitTime.isRfid)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi, size: 12, color: Colors.green),
                ),
              ),
          ],
        ),
        title: Text(
          splitTime.runnerName,
          style: TextStyle(fontWeight: isNew ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text(splitTime.splitName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(splitTime.absoluteTime),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNew ? Colors.green : null,
              ),
            ),
            if (splitTime.timeFromStart != null)
              Text(
                splitTime.timeFromStart!,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}