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

      expect(find.text('OST Remote'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders email field with correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text('Email'), findsOneWidget);
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

      final passwordField =
          tester.widgetList<TextField>(find.byType(TextField)).last;
      expect(passwordField.obscureText, true);
    });

    testWidgets('can enter email text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('can enter password text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.pump();

      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets('no CircularProgressIndicator before login attempt',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Log In'), findsOneWidget);
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

      await tester.enterText(find.byType(TextField).first, 'bad@email.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Login failed. Please check your credentials.'),
          findsOneWidget);
    });

    testWidgets('has an AppBar with correct title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('OST Remote'), findsOneWidget);
    });

    testWidgets('has a Sign Up link', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );

      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });
  });
}
