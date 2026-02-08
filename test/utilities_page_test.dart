import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_split_time_v2/pages/utilities/about_screen.dart';
import 'package:open_split_time_v2/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake screens so no timers or API calls run
class FakeRefreshScreen extends StatelessWidget {
  const FakeRefreshScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text("Fake Refresh Screen"));
}

class FakeChangeStationScreen extends StatelessWidget {
  const FakeChangeStationScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text("Fake Change Station"));
}

// Wrapper to override button callbacks
class TestUtilitiesWrapper extends StatelessWidget {
  const TestUtilitiesWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Column(
              children: [
                // About stays real
                ElevatedButton(
                  child: const Text("About"),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),

                // Refresh overridden → Fake screen
                ElevatedButton(
                  child: const Text("Refresh Data"),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FakeRefreshScreen()));
                  },
                ),

                // Change overridden → Fake screen
                ElevatedButton(
                  child: const Text("Change Station"),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FakeChangeStationScreen()));
                  },
                ),

                // Logout stays real
                ElevatedButton(
                  child: const Text("Logout"),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      "authToken": "TEST",
      "eventName": "Demo",
      "selectedStation": "S1",
      "stationList": ["S1", "S2"],
    });
  });

  testWidgets("Buttons render", (tester) async {
    await tester.pumpWidget(const TestUtilitiesWrapper());
    expect(find.text("About"), findsOneWidget);
    expect(find.text("Refresh Data"), findsOneWidget);
    expect(find.text("Change Station"), findsOneWidget);
    expect(find.text("Logout"), findsOneWidget);
  });

  testWidgets("About navigates to AboutScreen", (tester) async {
    await tester.pumpWidget(const TestUtilitiesWrapper());
    await tester.tap(find.text("About"));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets("Refresh Data navigates to FakeRefreshScreen", (tester) async {
    await tester.pumpWidget(const TestUtilitiesWrapper());
    await tester.tap(find.text("Refresh Data"));
    await tester.pumpAndSettle();
    expect(find.text("Fake Refresh Screen"), findsOneWidget);
  });

  testWidgets("Change Station navigates to FakeChangeStationScreen",
      (tester) async {
    await tester.pumpWidget(const TestUtilitiesWrapper());
    await tester.tap(find.text("Change Station"));
    await tester.pumpAndSettle();
    expect(find.text("Fake Change Station"), findsOneWidget);
  });

  testWidgets("Logout navigates to LoginPage", (tester) async {
    await tester.pumpWidget(const TestUtilitiesWrapper());
    await tester.tap(find.text("Logout"));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
