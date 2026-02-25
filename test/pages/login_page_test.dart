import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/pages/login.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  group('LoginPage Widget', () {
    testWidgets('renders login page with all elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Login Page'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders email field with correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Enter your username'), findsOneWidget);
    });

    testWidgets('renders password field with correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('password field obscures text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      final passwordField = tester.widgetList<TextField>(find.byType(TextField)).last;
      expect(passwordField.obscureText, true);
    });

    testWidgets('can enter email text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('can enter password text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'secret123');
      await tester.pump();

      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets('no CircularProgressIndicator before login attempt', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      // Before tapping login, no progress indicator should be shown
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Login button should be visible
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('pre-fills email from stored preferences', (tester) async {
      SharedPreferences.setMockInitialValues({'email': 'saved@email.com'});
      await PreferencesService().init();

      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('saved@email.com'), findsOneWidget);
    });

    testWidgets('shows error message on login failure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      // Fill and submit
      await tester.enterText(find.byType(TextField).first, 'bad@email.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.tap(find.text('Login'));

      // Wait for the network call to fail
      await tester.pumpAndSettle();

      // Should show error text
      expect(find.text('Login failed. Please check your credentials.'), findsOneWidget);
    });

    testWidgets('has an AppBar with correct title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
