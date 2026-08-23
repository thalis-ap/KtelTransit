import 'package:latlong2/latlong.dart';

import '../models/map_point.dart';

class FareService {
  // This is a temporary distance-based placeholder until multiple regions with different
  // pricing are supported. Remove this duplication when a proper FareService is implemented.
  static double calculateFare(MapPoint start, MapPoint dest) {
    final distanceCalc = const Distance();
    final meters = distanceCalc(
      LatLng(start.latitude, start.longitude),
      LatLng(dest.latitude, dest.longitude),
    );

    // Draft - Hard coded values (e.g. 2.2)
    final km = meters / 1000;
    if (km <= 14) return 2.2;

    double calculatedPrice = 2.20 + ((km - 14) * 0.137);
    if (calculatedPrice > 4.20) calculatedPrice = 4.20;

    return (calculatedPrice * 10).round() / 10.0;
  }

  static String fareAsString(double fare) {
    return fare > 0 ? "${fare.toStringAsFixed(2)}€" : "-€";
  }
}