import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:open_split_time_v2/services/preferences_service.dart';

class PageRouterDrawer extends StatelessWidget {
  const PageRouterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'OST Remote',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            title: const Text('Live Entry'),
            onTap: () async {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/eventSelect', // The route name for your EventSelect widget
                (route) => false, // This predicate returns false, destroying all previous history
              );
              Navigator.pushNamed(
                context,
                '/liveEntry',
              );
              developer.log('Navigated to Live Entry',
                  name: 'PageRouterDrawer');
            },
          ),
          ListTile(
            title: const Text('Review/Sync'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ReviewSync');
            },
          ),
          ListTile(
            title: const Text('Cross Check'),
            onTap: () {
              Navigator.pop(context);
              final prefs = PreferencesService();
              final eventSlug = prefs.selectedEventSlug;
              final aidStation = prefs.selectedAidStation;

              if (context.mounted) {
                Navigator.pushNamed(context, '/CrossCheck', arguments: {
                  'eventSlug': eventSlug,
                  'aidStation': aidStation,
                });
              }
            },
          ),
          ListTile(
            title: const Text("Utilities"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/Utilities');
            },
          ),
          // Add more menu items here
        ],
      ),
    );
  }
}
