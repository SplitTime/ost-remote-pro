import 'package:flutter/material.dart';
import 'package:open_split_time_v2/pages/Utilities/refresh_error.dart';
import 'package:open_split_time_v2/pages/Utilities/refresh_success.dart';
import 'package:open_split_time_v2/services/network_manager.dart';
import 'package:open_split_time_v2/pages/Utilities/refresh_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RefreshLoadingScreen extends StatefulWidget {
  const RefreshLoadingScreen({super.key});

  @override
  State<RefreshLoadingScreen> createState() => _RefreshLoadingScreenState();
}

class _RefreshLoadingScreenState extends State<RefreshLoadingScreen> {
  double progress = 0.0;

  final RefreshDataService _refreshService =
      RefreshDataService(network: NetworkManager());

  @override
  void initState() {
    super.initState();
    _runRefresh();
  }

  Future<void> _runRefresh() async {
    setState(() => progress = 0.1);

    final prefs = await SharedPreferences.getInstance();
    final eventSlug = prefs.getString('eventSlug');

    if (eventSlug == null || eventSlug.trim().isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RefreshErrorScreen(
            message:
                'No event is selected yet. Go to Live Entry once, then run Refresh Data again.',
          ),
        ),
      );
      return;
    }

    try {
      await _refreshService.refreshEventData(
        eventSlug: eventSlug,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => progress = p);
        },
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RefreshSuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RefreshErrorScreen(message: e.toString())),
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
          Image.asset("assets/images/ost_logo.jpg", height: 130),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: LinearProgressIndicator(
              value: progress <= 0 ? null : progress,
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
