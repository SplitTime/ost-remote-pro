// lib/services/action_cable_service.dart
//
// WebSocket service using ActionCable protocol
// Connects to OST backend and receives real-time updates

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../models/split_time.dart';

class ActionCableService {
  WebSocketChannel? _channel;
  StreamController<SplitTime>? _controller;
  String? _token;
  
  void setToken(String token) => _token = token;
  
  // Subscribe to event updates
  Stream<SplitTime> subscribeToEvent(int eventId) {
    _controller = StreamController<SplitTime>.broadcast();
    
    // Connect to ActionCable WebSocket
    final wsUrl = ApiConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/cable?token=$_token'),
    );
    
    // Subscribe to event channel
    final subscribeMessage = {
      'command': 'subscribe',
      'identifier': jsonEncode({
        'channel': 'EventChannel',
        'event_id': eventId,
      }),
    };
    
    _channel!.sink.add(jsonEncode(subscribeMessage));
    
    // Listen for messages
    _channel!.stream.listen(
      (data) => _handleMessage(data),
      onError: (error) => _controller!.addError(error),
      onDone: () => _controller!.close(),
    );
    
    return _controller!.stream;
  }
  
  void _handleMessage(dynamic data) {
    final message = jsonDecode(data);
    
    // ActionCable message types
    if (message['type'] == 'ping') return;
    if (message['type'] == 'welcome') return;
    if (message['type'] == 'confirm_subscription') {
      print('✓ Subscribed to event channel');
      return;
    }
    
    // Data message from broadcast
    if (message['message'] != null) {
      final payload = message['message'];
      
      if (payload['type'] == 'split_time_created') {
        final splitTime = SplitTime.fromJson(payload['data']);
        _controller?.add(splitTime);
      }
    }
  }
  
  void unsubscribe() {
    _channel?.sink.close();
    _controller?.close();
    _channel = null;
    _controller = null;
  }
  
  void dispose() => unsubscribe();
}