import 'package:flutter/material.dart';
import 'package:open_split_time_v2/pages/live_entry.dart';
import 'package:open_split_time_v2/pages/login.dart';
import 'package:open_split_time_v2/pages/review_sync.dart';
import 'package:open_split_time_v2/pages/Utilities/utilities.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService().init();
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
        '/ReviewSync': (context) => const ReviewSyncPage(),
        '/eventSelect': (context) => const EventSelect(),
        '/Utilities': (context) => const UtilitiesPage(),
      },
    );
  }
}
