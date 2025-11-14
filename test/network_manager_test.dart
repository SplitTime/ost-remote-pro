import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:open_split_time_v2/services/network_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load .env file before running tests
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded');
  });

  test('Login test - shows actual error on macOS vs Windows', () async {
    final networkManager = NetworkManager();
    
    // Get credentials from .env
    final email = dotenv.env['TEST_USERNAME'];
    final password = dotenv.env['TEST_PASSWORD'];
    
    if (email == null || password == null) {
      fail('TEST_EMAIL and TEST_PASSWORD must be set in .env file');
    }
    
    print('\n=== Testing on ${Platform.operatingSystem} ===\n');
    print('Using email: $email');
    
    try {
      await networkManager.login(email, password);
      
      print('✓ Login completed successfully');
    } catch (e, stackTrace) {
      print('✗ Login failed');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('\nStack trace:\n$stackTrace');
    }
  });
}