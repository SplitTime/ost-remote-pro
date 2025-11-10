



import 'package:flutter/material.dart';
import 'services/network_manager.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/action_cable_service.dart';
import 'providers/live_timing_provider.dart';
import 'screens/events_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
