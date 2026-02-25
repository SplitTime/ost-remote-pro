import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/two_state_toggle.dart';

void main() {
  group('TwoStateToggle Widget', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoStateToggle(
              label: 'Continuing',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Continuing'), findsOneWidget);
    });

    testWidgets('renders Switch widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoStateToggle(
              label: 'Test',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Switch reflects true value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoStateToggle(
              label: 'Test',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('Switch reflects false value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoStateToggle(
              label: 'Test',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('tapping Switch calls onChanged', (tester) async {
      bool? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoStateToggle(
              label: 'Test',
              value: false,
              onChanged: (val) => changedValue = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changedValue, true);
    });

    testWidgets('displays different labels correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TwoStateToggle(
                  label: 'Continuing',
                  value: true,
                  onChanged: (_) {},
                ),
                TwoStateToggle(
                  label: 'With Pacer',
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Continuing'), findsOneWidget);
      expect(find.text('With Pacer'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });
  });
}
