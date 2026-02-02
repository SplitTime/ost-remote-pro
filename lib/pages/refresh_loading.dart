import 'package:flutter/material.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';
import 'package:open_split_time_v2/pages/refresh_success.dart';

class RefreshLoadingScreen extends StatefulWidget {
  const RefreshLoadingScreen({super.key});

  @override
  State<RefreshLoadingScreen> createState() => _RefreshLoadingScreenState();
}

class _RefreshLoadingScreenState extends State<RefreshLoadingScreen> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  Future<void> _startProgress() async {

    final PreferencesService _prefs = PreferencesService();
    // Animate progress bar over 2 seconds
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      setState(() {
        progress = i / 100;
      });
    }

    // After animation, go to success page
    int refreshSuccess = await _prefs.refreshParticipantData();
    if(refreshSuccess == 0){
      // Handle failure case if needed don't have a page for that yet
    }
    else if(refreshSuccess == 1) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RefreshSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          Image.asset(
            "assets/images/ost_logo.jpg",
            height: 130,
            //color: Colors.white,
          ),
          const SizedBox(height: 20),

          const Text(
            "OST Remote",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // ANIMATED PROGRESS BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
