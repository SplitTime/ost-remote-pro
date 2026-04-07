import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_split_time_v2/pages/signup.dart';

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
  group('SignUpPage Widget', () {
    testWidgets('has AppBar with Create Account title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows browser icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byIcon(Icons.open_in_browser_outlined), findsOneWidget);
    });

    testWidgets('shows heading text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Create your account on OpenSplitTime'), findsOneWidget);
    });

    testWidgets('shows description text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(
        find.textContaining('OST Remote uses your OpenSplitTime account'),
        findsOneWidget,
      );
    });

    testWidgets('shows Sign up on OpenSplitTime button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Sign up on OpenSplitTime'), findsOneWidget);
    });

    testWidgets('shows Already have an account text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets('shows Log In link', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('has no form fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('no CircularProgressIndicator shown', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('tapping Log In link pops the page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginStub(),
          routes: {'/signup': (_) => const SignUpPage()},
        ),
      );

      await tester.tap(find.text('Go to Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);

      await tester.ensureVisible(find.text('Log In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsNothing);
    });

    testWidgets('shows open_in_new icon on button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });
  });
}
