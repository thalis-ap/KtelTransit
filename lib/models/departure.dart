import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/utilities/time_format.dart';

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

  String getSubtitle() {
    if (originStop.stopId == departureStop.stopId) {
      return "Αναχώρηση από ${originStop.name} στις ${TimeFormat.dateTimeToFormattedString(originDepartureTime)}";
    }
    return "Άφιξη σε ${departureStop.name} στις ${TimeFormat.dateTimeToFormattedString(departureTime)}";
  }
}
