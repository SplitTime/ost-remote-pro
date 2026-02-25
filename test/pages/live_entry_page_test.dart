import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/pages/live_entry.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/clock.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/numpad.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  Widget buildScreen() {
    return MaterialApp(
      navigatorObservers: [LiveEntryScreen.routeObserver],
      home: const LiveEntryScreen(),
    );
  }

  group('LiveEntryScreen Widget', () {
    testWidgets('renders AppBar with title "Live Entry"', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Live Entry'), findsOneWidget);
    });

    testWidgets('shows "000" placeholder when no bib entered', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('000'), findsOneWidget);
    });

    testWidgets('renders ClockWidget', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(ClockWidget), findsOneWidget);
    });

    testWidgets('renders "Continuing" toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Continuing'), findsOneWidget);
    });

    testWidgets('renders "With Pacer" toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('With Pacer'), findsOneWidget);
    });

    testWidgets('renders two TwoStateToggle widgets', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(TwoStateToggle), findsNWidgets(2));
    });

    // loadParticipants() has no awaits so it completes synchronously —
    // after pump() the NumPad is already visible.
    testWidgets('renders NumPad after loading completes', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(); // drains microtasks — loading completes

      expect(find.byType(NumPad), findsOneWidget);
    });

    // Station buttons contain ' in' / ' out' (aidStation + direction).
    // NumPad keys ('1'..'9','0','←') never contain those substrings.
    testWidgets('station in/out buttons are present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.textContaining(' in'), findsOneWidget);
      expect(find.textContaining(' out'), findsOneWidget);
    });
  });
}
