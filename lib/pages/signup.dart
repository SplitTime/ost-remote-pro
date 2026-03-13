import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const _signUpUrl = 'https://www.opensplittime.org/users/sign_up';

  Future<void> _openSignUp(BuildContext context) async {
    final uri = Uri.parse(_signUpUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser. Visit opensplittime.org to sign up.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.open_in_browser_outlined,
                  size: 72, color: colorScheme.inversePrimary),
              const SizedBox(height: 24),
              Text(
                'Create your account on OpenSplitTime',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'OST Remote uses your OpenSplitTime account. '
                'Tap below to register on the website, then come back and log in.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => _openSignUp(context),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.inversePrimary,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Sign up on OpenSplitTime',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?',
                      style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        foregroundColor: colorScheme.inversePrimary),
                    child: const Text('Log In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
