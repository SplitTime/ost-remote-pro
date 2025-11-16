import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

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
              Navigator.pop(context);
              try {
                final prefs = await SharedPreferences.getInstance();
                final savedEvent = prefs.getString('selectedEvent');
                final savedAid = prefs.getString('selectedAidStation');
                final savedSlug = prefs.getString('selectedEventSlug');

                if (savedEvent != null && savedAid != null && savedSlug != null) {
                  Navigator.pushNamed(context, '/liveEntry', arguments: {
                    'event': savedEvent,
                    'aidStation': savedAid,
                    'eventSlug': savedSlug,
                  });
                } else {
                  // Fallback to demo values if nothing persisted
                  Navigator.pushNamed(context, '/liveEntry', arguments: {
                    'event': 'Demo Event',
                    'aidStation': 'Demo Station',
                    'eventSlug': 'demo-event',
                  });
                }
              } catch (e) {
                // On error, fall back to demo values
                Navigator.pushNamed(context, '/liveEntry', arguments: {
                  'event': 'Demo Event',
                  'aidStation': 'Demo Station',
                  'eventSlug': 'demo-event',
                });
              }

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
