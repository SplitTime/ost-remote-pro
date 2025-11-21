import 'package:flutter/material.dart';
import 'package:open_split_time_v2/pages/live_entry.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About OST"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // Logo
            Image.asset(
               "assets/images/ost_logo.jpg",
              height: 100,
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "OST Remote",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007AFF),
              ),
            ),

            const SizedBox(height: 10),

            // Copyright
            const Text(
              "(c) 2020 OpenSplitTime Company",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Version
            const Text(
              "Version: 3.1.1",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            // Servers Header
            const Text(
              "Servers",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Primary: https://www.opensplittime.org/api/v1/",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Fallback: http://www.opensplittime.org/api/v1/",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Contact
            const Text(
              "Contact: support@opensplittime.org",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Fun message
            const Text(
              "Go git ‘er done!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // Return button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                //Navigator.pop(context);
                Navigator.pushNamed(context, '/liveEntry', arguments: {
                'event': 'Demo Event',
                'aidStation': 'Demo Station',
                'eventSlug': 'demo-event',
              });
              },
              child: const Text(
                "Return To Live Entry  →",
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
    );
  }
}
