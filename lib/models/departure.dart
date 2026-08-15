import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:ktel_transit/l10n/app_localizations.dart'; // Make sure this path is correct for your app

class Departure {
  final Stop originStop, departureStop, destinationStop;
  final DateTime originDepartureTime, departureTime;

  final String routeName;

  Departure({
    required this.originStop,
    required this.departureStop,
    required this.destinationStop,
    required this.originDepartureTime,
    required this.departureTime,
    required this.routeName,
  });

  String getSubtitle(AppLocalizations l10n, String languageCode) {
    if (originStop.stopId == departureStop.stopId) {
      final stopName = originStop.getLocalizedName(languageCode);
      final time = TimeFormat.dateTimeToFormattedString(originDepartureTime);

      // Using your existing localization and appending the time
      return "${l10n.departureFrom(stopName)} - $time";
    } else {
      final stopName = departureStop.getLocalizedName(languageCode);
      final time = TimeFormat.dateTimeToFormattedString(departureTime);

      // Using your existing localization and appending the time
      return "${l10n.estimatedArrivalAt(stopName)} $time";
    }
  }
}