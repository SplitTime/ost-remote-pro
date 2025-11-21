import 'package:flutter/material.dart';
import 'package:open_split_time_v2/pages/login.dart';
import 'package:open_split_time_v2/pages/event_select.dart';
import 'package:open_split_time_v2/pages/review_sync.dart';
import 'package:open_split_time_v2/pages/about_screen.dart';


class UtilitiesPage extends StatelessWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Utilities"),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // About Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(55),
                  shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
                child: const Text("About",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Refresh Data Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(55),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReviewSyncPage()),
                  );
                },
                child: const Text(
                  "Refresh Data",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Change Station Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(55),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventSelect()),
                  );
                },
                child: const Text(
                  "Change Station",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(55),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}
