import 'package:latlong2/latlong.dart';
import '../models/stop.dart';

class DistanceService {
  static final Distance _distanceCalculator = const Distance();

  static double calculateSLD(LatLng point1, LatLng point2) {
    return _distanceCalculator.as(
      LengthUnit.Meter,
      point1,
      point2,
    ).toDouble();
  }

  /// Returns a List of MapEntries of the form Stop, double sorted by their
  /// double value, which is the distance of the key (Stop) from the target
  /// coordinates
  static List<MapEntry<Stop, double>> findNearestStops(
      LatLng target,
      List<Stop> allStops, {
        int limit = 5,
      }) {
    final distances = allStops.map((stop) {
      final stopDistance = calculateSLD(
        target,
        LatLng(stop.latitude, stop.longitude),
      );
      return MapEntry(stop, stopDistance);
    }).toList();

    distances.sort((a, b) => a.value.compareTo(b.value));

    return distances.take(limit).toList();
  }
}