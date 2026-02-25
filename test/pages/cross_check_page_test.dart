import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/pages/crosscheck/cross_check.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  group('CrossCheckPage Widget', () {
    testWidgets('renders AppBar with title "Cross Check"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Cross Check'), findsOneWidget);
    });

    testWidgets('shows loading indicator on initial render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      // Before settling, the page is loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Bulk Select" button in AppBar leading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      expect(find.text('Bulk Select'), findsOneWidget);
    });

    testWidgets('shows "Menu" action in AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('"Bulk Select" toggles to "Cancel" when tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      // Initially shows "Bulk Select"
      expect(find.text('Bulk Select'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.text('Bulk Select'));
      await tester.pump();

      // After tap, shows "Cancel"
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Bulk Select'), findsNothing);
    });

    testWidgets('"Cancel" reverts to "Bulk Select" when tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      await tester.tap(find.text('Bulk Select'));
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Bulk Select'), findsOneWidget);
    });

    testWidgets('shows filter tabs and "Return To Live Entry" after loading',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      // Wait for all async work (network calls all return null/empty safely)
      await tester.pumpAndSettle();

      // Bottom filter tabs
      expect(find.text('Recorded'), findsOneWidget);
      expect(find.text('Expected'), findsOneWidget);
      expect(find.text('Return To Live Entry'), findsOneWidget);
    });

    testWidgets('shows "Your Location:" header after loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Location:'), findsOneWidget);
    });

    testWidgets('shows default station name after loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrossCheckPage()),
      );

      await tester.pumpAndSettle();

      // Default _splitName is 'Demo Station'
      expect(find.text('Demo Station'), findsOneWidget);
    });
  });
}
