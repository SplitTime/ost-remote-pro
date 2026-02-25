import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/clock.dart';

void main() {
  group('ClockWidget', () {
    testWidgets('renders a Text widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockWidget(),
          ),
        ),
      );

      // ClockWidget uses StreamBuilder which renders a Text widget
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('displays time in HH:mm:ss format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockWidget(),
          ),
        ),
      );

      // Pump once to get the first stream emission
      await tester.pump(const Duration(seconds: 1));

      final textFinder = find.byType(Text);
      final textWidget = tester.widget<Text>(textFinder);
      final timeText = textWidget.data ?? '';

      // Should match HH:mm:ss pattern
      final regex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
      expect(timeText, matches(regex));
    });

    testWidgets('text is styled with red color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockWidget(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('text has bold font weight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockWidget(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('text has font size 15', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockWidget(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontSize, 15);
    });
  });
}
