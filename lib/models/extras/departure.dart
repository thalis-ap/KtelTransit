import 'package:ktel_transit/models/gtfs/stops/stop.dart';
import 'package:ktel_transit/utilities/time_utils.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';

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
      final stopName = originStop.name;
      final time = TimeFormat.dateTimeToFormattedStringHoursMinutes(originDepartureTime);

      return "${l10n.departureFrom(stopName)} - $time";
    } else {
      final stopName = departureStop.name;
      final time = TimeFormat.dateTimeToFormattedStringHoursMinutes(departureTime);

      return "${l10n.estimatedArrivalAt(stopName)} $time";
    }
  }
}