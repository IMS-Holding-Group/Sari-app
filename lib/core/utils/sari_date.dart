/// Formats dates as `YYYY/M/Dم H:MMص|م` (Gregorian, 12-hour, Latin digits).
/// Date and time are wrapped in LTR isolates so they never flip inside RTL text.
class SariDate {
  static String date(DateTime t) => '${t.year}/${t.month}/${t.day}م';

  static String time(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final suffix = t.hour < 12 ? 'ص' : 'م';
    return '$hour:${t.minute.toString().padLeft(2, '0')}$suffix';
  }

  static String format(DateTime t) => '\u2066${date(t)}\u2069 \u2066${time(t)}\u2069';
}
