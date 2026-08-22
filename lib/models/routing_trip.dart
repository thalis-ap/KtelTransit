import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/walking_trip.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:latlong2/latlong.dart';

import 'map_point.dart';

/// This class acts as a trip-orchestrator. It includes everything needed
/// for every kind of trip, walk, bus, total time, ...
class RoutingTrip {
  final MapPoint startPoint, destinationPoint;

  // The walk trip that takes you from the start point to the start bus stop
  WalkingTrip? accessTrip;

  // The bus trip from start stop to destination stop (not point!)
  BusTrip? busTrip;

  // The walk trip that takes you from the desintation bus stop to the destination point
  WalkingTrip? egressTrip;

  double get duration =>
      (accessTrip?.duration ?? 0) +
      (busTrip?.estimatedDuration ?? 0) +
      (egressTrip?.duration ?? 0);

  double get accessDuration => accessTrip?.duration ?? 0;

  double get transitEstimatedDuration =>
      (busTrip?.estimatedDuration ?? 0).toDouble();

  double get transitSafeDuration => (busTrip?.safeDuration ?? 0).toDouble();

  double get egressDuration => egressTrip?.duration ?? 0;

  double get walkingDuration =>
      (accessTrip?.duration ?? 0) + (egressTrip?.duration ?? 0);

  RoutingTrip({
    required this.startPoint,
    required this.destinationPoint,
    this.accessTrip,
    this.busTrip,
    this.egressTrip,
  });

  // -------------------- DRAFT START --------------------
  // TODO: Replace all fare related function with region-specific GTFS fare data (fare_attributes.txt, fare_rules.txt)
  double get estimatedFare => calculateFare(startPoint, destinationPoint);

  // This is a temporary distance-based placeholder until multiple regions with different
  // pricing are supported. Remove this duplication when a proper FareService is implemented.
  static double calculateFare(MapPoint start, MapPoint dest) {
    final distanceCalc = const Distance();
    final meters = distanceCalc(
      LatLng(start.latitude, start.longitude),
      LatLng(dest.latitude, dest.longitude),
    );

    final km = meters / 1000;
    if (km <= 14) return 2.2;

    double calculatedPrice = 2.20 + ((km - 14) * 0.137);
    if (calculatedPrice > 4.20) calculatedPrice = 4.20;

    return (calculatedPrice * 10).round() / 10.0;
  }

  String get estimatedFareAsString =>
      estimatedFare > 0 ? "${estimatedFare.toStringAsFixed(2)}€" : "-€";

  static String calculateEstimatedFareAsString(fare) {
    return fare > 0 ? "${fare.toStringAsFixed(2)}€" : "-€";
  }

  // -------------------- DRAFT END --------------------

  DateTime getDepartureDateOnly(DateTime selectedTime) {
    return TimeFormat.dateTimeToDateOnly(getDepartureDateTime(selectedTime));
  }

  DateTime getDepartureDateTime(DateTime selectedTime) {
    if (busTrip == null) return selectedTime;

    return busTrip!.startDepartureDateTime.subtract(
      Duration(seconds: accessTrip?.duration.toInt() ?? 0),
    );
  }

  DateTime getArrivalDateTime(DateTime departureTime) {
    // Edge Case: No bus involved, just pure walking!
    if (busTrip == null) {
      int totalWalkSeconds = 0;
      if (accessTrip != null) totalWalkSeconds += accessTrip!.duration.toInt();
      if (egressTrip != null) totalWalkSeconds += egressTrip!.duration.toInt();

      return departureTime.add(Duration(seconds: totalWalkSeconds));
    }

    // Standard Case: The anchor is the time the bus arrives at the destination stop
    DateTime finalArrival = busTrip!.destArrivalDateTime;

    // Add egress walk duration if it exists
    if (egressTrip != null) {
      finalArrival = finalArrival.add(
        Duration(seconds: egressTrip!.duration.toInt()),
      );
    }

    return finalArrival;
  }
}
