import 'package:flutter/material.dart';
import 'dart:developer' as developer;

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
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/liveEntry', arguments: {
                // TODO: Pass actual event and aid station data, issue #22
                // Use memory?
                'event': 'Demo Event',
                'aidStation': 'Demo Station',
                'eventSlug': 'demo-event',
              });

              developer.log('Navigated to Live Entry', name: 'PageRouterDrawer');
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
