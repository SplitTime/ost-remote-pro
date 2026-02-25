import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_split_time_v2/widgets/live_entry_widgets/numpad.dart';

void main() {
  group('NumPad Widget', () {
    late List<String> pressedDigits;
    late int backspaceCount;

    setUp(() {
      pressedDigits = [];
      backspaceCount = 0;
    });

    Widget buildTestNumPad() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: NumPad(
              onNumberPressed: (digit) => pressedDigits.add(digit),
              onBackspace: () => backspaceCount++,
            ),
          ),
        ),
      );
    }

    testWidgets('renders all number buttons 0-9', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      for (var i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('renders the * button', (tester) async {
      await tester.pumpWidget(buildTestNumPad());
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('renders the backspace icon', (tester) async {
      await tester.pumpWidget(buildTestNumPad());
      expect(find.byIcon(Icons.backspace), findsOneWidget);
    });

    testWidgets('tapping a number calls onNumberPressed with correct digit', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      await tester.tap(find.text('5'));
      await tester.pump();

      expect(pressedDigits, ['5']);
    });

    testWidgets('tapping multiple numbers builds up digit list', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(pressedDigits, ['1', '2', '3']);
    });

    testWidgets('tapping * calls onNumberPressed with *', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      await tester.tap(find.text('*'));
      await tester.pump();

      expect(pressedDigits, ['*']);
    });

    testWidgets('tapping backspace calls onBackspace', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      await tester.tap(find.byIcon(Icons.backspace));
      await tester.pump();

      expect(backspaceCount, 1);
    });

    testWidgets('tapping backspace multiple times increments count', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      await tester.tap(find.byIcon(Icons.backspace));
      await tester.tap(find.byIcon(Icons.backspace));
      await tester.pump();

      expect(backspaceCount, 2);
    });

    testWidgets('has correct layout with 4 rows', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      // Should have 12 ElevatedButtons total (4 rows x 3 columns)
      expect(find.byType(ElevatedButton), findsNWidgets(12));
    });

    testWidgets('all number buttons 0-9 fire correct callbacks', (tester) async {
      await tester.pumpWidget(buildTestNumPad());

      for (var i = 0; i <= 9; i++) {
        await tester.tap(find.text('$i'));
      }
      await tester.pump();

      // Tapping 0-9 in order; all digits should be present
      expect(pressedDigits.toSet(), {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'});
      expect(pressedDigits, hasLength(10));
    });
  });
}
