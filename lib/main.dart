import 'package:flutter/material.dart';
import 'package:open_split_time_v2/pages/live_entry.dart';
import 'package:open_split_time_v2/pages/login.dart';

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
      routes: {
        '/liveEntry': (context) => const LiveEntryScreen(),
      },
    );
  }
}
