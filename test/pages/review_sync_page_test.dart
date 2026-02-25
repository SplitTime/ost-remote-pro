import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/pages/review_sync.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';
import 'package:open_split_time_v2/widgets/review_sync_widgets/sync_export_footer.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  group('ReviewSyncPage Widget', () {
    testWidgets('renders AppBar with title "Review/Sync"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Review/Sync'), findsOneWidget);
    });

    testWidgets('shows "Sort By:" label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sort By:'), findsOneWidget);
    });

    testWidgets('shows "Aa = Synced" legend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aa = Synced'), findsOneWidget);
    });

    testWidgets('shows SyncExportFooter at the bottom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SyncExportFooter), findsOneWidget);
    });

    testWidgets('footer contains "Sync" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync'), findsOneWidget);
    });

    testWidgets('footer contains share/export icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });

    testWidgets('sort dropdown default value is "Name"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      // The dropdown widget shows the current value "Name"
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('shows empty data table when no local entries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReviewSyncPage()),
      );
      await tester.pumpAndSettle();

      // No spinner — page loaded successfully without network
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
