import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:open_split_time_v2/services/preferences_service.dart';

class PageRouterDrawer extends StatelessWidget {
  const PageRouterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          // Runner background image (bottom-aligned, faded)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/runner_bg.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Menu content
          SafeArea(
            child: Column(
              children: [
                // Close button row
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.close,
                              color: Colors.grey.shade500, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // OST Logo
                ClipOval(
                  child: Image.asset(
                    'assets/images/ost_logo.jpg',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: const Icon(Icons.timer, size: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'OST Remote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),

                // Menu items
                _MenuItem(
                  title: 'Live Entry',
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/eventSelect',
                      (route) => false,
                    );
                    Navigator.pushNamed(context, '/liveEntry');
                    developer.log('Navigated to Live Entry',
                        name: 'PageRouterDrawer');
                  },
                ),
                const Divider(height: 1),

                _MenuItem(
                  title: 'Review / Sync',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/ReviewSync');
                  },
                ),
                const Divider(height: 1),

                _MenuItem(
                  title: 'Cross Check',
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
                const Divider(height: 1),

                _MenuItem(
                  title: 'Utilities',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/Utilities');
                  },
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MenuItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
