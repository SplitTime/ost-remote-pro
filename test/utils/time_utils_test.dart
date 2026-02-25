import 'package:flutter_test/flutter_test.dart';
import 'package:open_split_time_v2/utils/time_utils.dart';

void main() {
  group('TimeUtils', () {
    group('formatEnteredTimeLocal', () {
      test('should return a non-empty string', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        expect(result, isNotEmpty);
      });

      test('should match expected date-time format YYYY-MM-DD HH:MM:SS±HH:MM', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        // Pattern: 2024-06-15 14:30:45+02:00 or 2024-06-15 14:30:45-05:00
        final regex = RegExp(
          r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$',
        );
        expect(result, matches(regex));
      });

      test('should contain current year', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final currentYear = DateTime.now().year.toString();
        expect(result, startsWith(currentYear));
      });

      test('should contain current month and day', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final now = DateTime.now();
        final expectedMonth = now.month.toString().padLeft(2, '0');
        final expectedDay = now.day.toString().padLeft(2, '0');
        expect(result, contains('-$expectedMonth-$expectedDay'));
      });

      test('should contain timezone offset', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        // Should end with +HH:MM or -HH:MM
        final offsetRegex = RegExp(r'[+-]\d{2}:\d{2}$');
        expect(result, matches(offsetRegex));
      });

      test('should have correct length (25 characters)', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        // "2024-06-15 14:30:45+02:00" = 25 chars
        expect(result.length, 25);
      });

      test('two consecutive calls should have the same date portion', () {
        final result1 = TimeUtils.formatEnteredTimeLocal();
        final result2 = TimeUtils.formatEnteredTimeLocal();
        // Date portion (first 10 chars) should be identical
        expect(result1.substring(0, 10), result2.substring(0, 10));
      });
    });
  });
}
