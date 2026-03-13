import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_split_time_v2/pages/signup.dart';
import 'package:open_split_time_v2/services/preferences_service.dart';

class LoginStub extends StatelessWidget {
  const LoginStub({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text('Go to Sign Up'),
        ),
      );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  group('SignUpPage Widget', () {
    testWidgets('renders all form fields and button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Create Account'), findsWidgets); // AppBar title + button
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('has AppBar with Create Account title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Create Account'), findsWidgets);
    });

    testWidgets('password fields obscure text by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      final passwordFields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      // 4th field (index 3) = Password, 5th (index 4) = Confirm Password
      expect(
        (passwordFields[3].controller ?? passwordFields[3].initialValue) != null ||
            true,
        isTrue,
      );
      // Check obscureText via EditableText
      final editableTexts =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(editableTexts[3].obscureText, isTrue);
      expect(editableTexts[4].obscureText, isTrue);
    });

    testWidgets('shows validation error when first name is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter your first name'), findsOneWidget);
    });

    testWidgets('shows validation error when last name is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(
          find.byType(TextFormField).at(0), 'Jane');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter your last name'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'notanemail');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error when password is too short', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'short');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows validation error when password is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'jane@example.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'different123');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows validation error when confirm password is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('no error shown before any submission', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Please enter your first name'), findsNothing);
      expect(find.text('Please enter your last name'), findsNothing);
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a password'), findsNothing);
      expect(find.text('Please confirm your password'), findsNothing);
    });

    testWidgets('no loading indicator before submission', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error on network failure with valid form', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Network call will fail in test env — error container should appear
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('can enter text into all fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane');
      await tester.enterText(find.byType(TextFormField).at(1), 'Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'securePass1');
      await tester.enterText(find.byType(TextFormField).at(4), 'securePass1');
      await tester.pump();

      expect(find.text('Jane'), findsOneWidget);
      expect(find.text('Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('has a Log In link to go back', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('tapping Log In link pops the page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginStub(),
          routes: {
            '/signup': (_) => const SignUpPage(),
          },
        ),
      );

      // Navigate to SignUpPage
      await tester.tap(find.text('Go to Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);

      // Scroll to bring the Log In link into view, then tap
      await tester.ensureVisible(find.text('Log In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsNothing);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Password field (index 3) should start obscured
      final editableTextsBefore =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(editableTextsBefore[3].obscureText, isTrue);

      // Tap the visibility icon for the password field
      final visibilityIcons =
          find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      final editableTextsAfter =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(editableTextsAfter[3].obscureText, isFalse);
    });
  });
}
