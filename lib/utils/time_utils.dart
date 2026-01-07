
class TimeUtils {
  /// Formats the current local time into a string with the format:
  /// "YYYY-MM-DD HH:MM:SS±HH:MM"
  /// Example: "2024-06-15 14:30:45+02:00"
  static String formatEnteredTimeLocal() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final oh = offset.inHours.abs().toString().padLeft(2, '0');
    final omin = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final offsetStr = '$sign$oh:$omin';
    return '$y-$mo-$d $hh:$mm:$ss$offsetStr';
  }
}
