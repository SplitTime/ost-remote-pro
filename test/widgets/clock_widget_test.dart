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

    // --- Negative / edge case tests ---

    testWidgets('continues to display valid HH:mm:ss format after multiple ticks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClockWidget()),
        ),
      );

      final regex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        final text = tester.widget<Text>(find.byType(Text)).data ?? '';
        expect(text, matches(regex), reason: 'Tick $i should still show a valid time');
      }
    });

    testWidgets('color is not blue or black', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClockWidget()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, isNot(Colors.blue));
      expect(textWidget.style?.color, isNot(Colors.black));
    });

    testWidgets('font weight is not light or thin', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClockWidget()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontWeight, isNot(FontWeight.w100)); // thin
      expect(textWidget.style?.fontWeight, isNot(FontWeight.w300)); // light
    });

    testWidgets('does not crash when rendered in a zero-height container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(height: 0, child: ClockWidget()),
          ),
        ),
      );

      // Widget is still in the tree — constrained layout should not throw
      expect(find.byType(ClockWidget), findsOneWidget);
    });
  });
}
