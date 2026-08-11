import '../l10n/app_localizations.dart';

class TimeFormat {
  /// Returns a String object that represents a human readable time of the
  /// DateTime object
  static String dateTimeToFormattedString(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
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

  static String gtfsTimeToFormattedString(DateTime baseDate, String gtfsTime) {
    final parts = gtfsTime.split(':');

    return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
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
}