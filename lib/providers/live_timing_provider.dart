// lib/providers/live_timing_provider.dart
//
// State management for real-time timing data via WebSocket

import 'package:flutter/foundation.dart';
import '../models/split_time.dart';
import '../services/action_cable_service.dart';

class LiveTimingProvider extends ChangeNotifier {
  final ActionCableService _cableService;
  
  List<SplitTime> _splitTimes = [];
  bool _isConnected = false;
  String? _error;
  
  List<SplitTime> get splitTimes => _splitTimes;
  bool get isConnected => _isConnected;
  String? get error => _error;
  int get totalReads => _splitTimes.length;
  int get rfidReads => _splitTimes.where((st) => st.isRfid).length;
  
  LiveTimingProvider(this._cableService);
  
  void startLiveTiming(int eventId) {
    _error = null;
    _isConnected = true;
    notifyListeners();
    
    // Subscribe to WebSocket
    _cableService.subscribeToEvent(eventId).listen(
      (splitTime) {
        // Add new split time to top of list
        _splitTimes.insert(0, splitTime);
        notifyListeners();
        
        print('✓ New split time: ${splitTime.runnerName} - ${splitTime.splitName}');
      },
      onError: (error) {
        _error = error.toString();
        _isConnected = false;
        notifyListeners();
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
    );
  }
  
  void stopLiveTiming() {
    _cableService.unsubscribe();
    _splitTimes.clear();
    _isConnected = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _cableService.dispose();
    super.dispose();
  }
}