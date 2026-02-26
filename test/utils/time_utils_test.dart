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

    group('field value ranges', () {
      // Format: "2026-02-25 14:30:45+05:30"
      //          0         1         2
      //          0123456789012345678901234

      test('hours portion is between 0 and 23', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final hours = int.parse(result.substring(11, 13));
        expect(hours, inInclusiveRange(0, 23));
      });

      test('minutes portion is between 0 and 59', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final minutes = int.parse(result.substring(14, 16));
        expect(minutes, inInclusiveRange(0, 59));
      });

      test('seconds portion is between 0 and 59', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final seconds = int.parse(result.substring(17, 19));
        expect(seconds, inInclusiveRange(0, 59));
      });

      test('month portion is between 1 and 12', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final month = int.parse(result.substring(5, 7));
        expect(month, inInclusiveRange(1, 12));
      });

      test('day portion is between 1 and 31', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final day = int.parse(result.substring(8, 10));
        expect(day, inInclusiveRange(1, 31));
      });

      test('timezone sign is + or -', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final sign = result[19];
        expect(['+', '-'], contains(sign));
      });

      test('timezone offset hours are between 0 and 14', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final offsetHours = int.parse(result.substring(20, 22));
        expect(offsetHours, inInclusiveRange(0, 14));
      });

      test('timezone offset minutes are between 0 and 59', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        final offsetMinutes = int.parse(result.substring(23, 25));
        expect(offsetMinutes, inInclusiveRange(0, 59));
      });

      test('separator between date and time is a space', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        expect(result[10], ' ');
      });

      test('date separators are dashes', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        expect(result[4], '-');
        expect(result[7], '-');
      });

      test('time separators are colons', () {
        final result = TimeUtils.formatEnteredTimeLocal();
        expect(result[13], ':');
        expect(result[16], ':');
        expect(result[22], ':');
      });
    });
  });
}
