import '../l10n/app_localizations.dart';

class TimeFormat {
  /// Returns a String object that represents a human readable time of the
  /// DateTime object
  static String dateTimeToFormattedStringHoursMinutes(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  static String dateTimeToFormattedStringDateMonth(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}";
  }

  /// Strips up the dateTime object from hours, minutes and seconds and returns
  /// a clear date only object (useful for date only comparisons)
  static DateTime dateTimeToDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Returns a String object that represents a human readable time of the
  /// difference between the two DateTime objects, localized to active language.
  static String waitTimeToFormattedString(
      DateTime departure,
      DateTime arrival,
      AppLocalizations l10n,
      ) {
    Duration diff = departure.difference(arrival);

    int mins = diff.inMinutes;
    if (mins >= 60) {
      int h = mins ~/ 60;
      int m = mins % 60;
      String mStr = m.toString().padLeft(2, '0');
      return m > 0 ? l10n.durationHoursMinutes(h, mStr) : l10n.durationHours(h);
    } else {
      return l10n.durationMinutes(mins);
    }
  }

  static String gtfsTimeToFormattedString(String gtfsTime) {
    final parts = gtfsTime.split(':');
    int hour = int.parse(parts[0]);
    // Handles next day hours
    if (hour >= 24) hour -= 24;
    return "${hour.toString().padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
  }

  /// Helper function to convert strings like 14:30:00 to DateTime objects
  /// given a baseDate for the date to be used
  static DateTime gtfsTimeToDateTime(DateTime baseDate, String gtfsTime) {
    final parts = gtfsTime.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    DateTime result = DateTime(baseDate.year, baseDate.month, baseDate.day);
    return result.add(Duration(hours: hours, minutes: minutes));
  }

  /// Returns a gtfsTime in minutes (08:30 -> 510)
  static int gtfsTimeToMinutes(String gtfsTime) {
    final parts = gtfsTime.split(':');
    final gtfsMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return gtfsMinutes;
  }

  static int gtfsTimeToSeconds(String gtfsTime) {
    final parts = gtfsTime.split(":");
    final gtfsSeconds = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60;
    return gtfsSeconds;
  }

  static int gtfsTimesToDiffSeconds(String after, String before) {
    return gtfsTimeToSeconds(after) - gtfsTimeToSeconds(before);
  }

  static String secondsToFormattedString(double seconds, AppLocalizations l10n) {
    int s = seconds.round();
    int h = s ~/ 3600;
    int m = s % 3600 ~/ 60;

    return h > 0 ? l10n.hoursMinutesFormat(h, m) : l10n.minutesFormat(m);

  }
}