import 'package:intl/intl.dart';

import 'money.dart';

/// Date and text formatting helpers.
///
/// Output is fixed to `en_US` so labels stay consistent regardless of the
/// device locale.
abstract final class Formatters {
  static final DateFormat _dayMonthYear = DateFormat('d MMMM yyyy', 'en_US');
  static final DateFormat _dayMonth = DateFormat('d MMM', 'en_US');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'en_US');

  static String currency(int paisa) => Money.format(paisa);

  static String signedCurrency(int paisa) => Money.formatSigned(paisa);

  /// `22 September 2026`
  static String date(DateTime value) => _dayMonthYear.format(value);

  /// `22 Sep`
  static String shortDate(DateTime value) => _dayMonth.format(value);

  /// `September 2026`
  static String monthYear(DateTime value) => _monthYear.format(value);

  /// `Today` / `Yesterday` / `22 September 2026` — for section headings.
  static String dayHeading(DateTime value) {
    final diff = _dayDelta(value);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return date(value);
  }

  /// `Today` / `Yesterday` / `22 Sep` — for compact list rows.
  static String relativeDay(DateTime value) {
    final diff = _dayDelta(value);
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return shortDate(value);
  }

  /// `Good morning` / `Good afternoon` / `Good evening`.
  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Up to two initials for avatars: `Hayat Ali` -> `HA`.
  static String initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final letters = words.take(2).map((word) => word[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  static int _dayDelta(DateTime value) => DateTime.now()
      .difference(DateTime(value.year, value.month, value.day))
      .inDays;
}
