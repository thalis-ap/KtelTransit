import 'package:latlong2/latlong.dart';

class WalkingTrip {
  final double distance; // meters
  final double duration; // seconds
  final List<LatLng> points;

  WalkingTrip({
    required this.distance,
    required this.duration,
    required this.points,
  });

  /// Returns an approximation of the duration needed to walk 'distance' meters
  /// Result is returned in seconds
  static double getDurationFromDistance(double distance) {
    return 0.72 * distance;
  }
}
