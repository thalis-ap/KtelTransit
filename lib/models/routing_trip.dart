import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/walking_trip.dart';
import 'package:ktel_transit/services/fare_service.dart';
import 'package:ktel_transit/utilities/time_format.dart';

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

  /// Full duration including wait times
  double get durationFull => duration + (busTrip?.totalWaitTime ?? 0);

  double get totalWaitTime => busTrip?.totalWaitTime ?? 0;

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

  // Returns -1 if its a walking trip only
  double get fare => busTrip?.totalFare ?? -1;

  String get fareAsString => FareService.fareAsString(fare);

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
