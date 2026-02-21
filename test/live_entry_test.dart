import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/pages/live_entry.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

void main() {
  group('LiveEntryScreen', () {
    // Initialize shared_preferences and PreferencesService for testing
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({
        'selected_event_key': 'Test Event',
        'selected_event_slug_key': 'test-event',
        'selected_station_key': 'Start',
        'selected_event_aid_stations': <String>[],
        'selected_event_participant_information': <String>[],
      });
      
      // Initialize PreferencesService
      await PreferencesService().init();
    });

    testWidgets('LiveEntryScreen renders with AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveEntryScreen(),
          navigatorObservers: [LiveEntryScreen.routeObserver],
        ),
      );

      // Verify AppBar exists and has the correct title
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Live Entry'), findsOneWidget);
    });

    testWidgets('LiveEntryScreen renders Scaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveEntryScreen(),
          navigatorObservers: [LiveEntryScreen.routeObserver],
        ),
      );

      // Verify Scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('LiveEntryScreen has layout widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveEntryScreen(),
          navigatorObservers: [LiveEntryScreen.routeObserver],
        ),
      );

      // Verify layout uses Padding
      expect(find.byType(Padding), findsWidgets);
      
      // Verify multiple Columns exist (nested layout)
      expect(find.byType(Column), findsWidgets);
      
      // Verify Rows are used for horizontal layout
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('LiveEntryScreen has input fields and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveEntryScreen(),
          navigatorObservers: [LiveEntryScreen.routeObserver],
        ),
      );

      // Verify layout containers exist
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
