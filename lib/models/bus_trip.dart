import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/services/fare_service.dart';
import 'package:latlong2/latlong.dart';

/// A single bus ride on one route, from one stop to another, with no
/// transfers in between. A BusTrip with a transfer is just 2+ of these.
class BusLeg {
  final List<LatLng>? points;
  final int? safeDuration; // seconds, from OSRM

  final String routeName;
  final DateTime departureDateTime;
  final DateTime arrivalDateTime;
  final int estimatedDuration; // seconds, from stop_times.txt
  final double fare;

  final Stop originStop;
  final Stop destinationStop;

  // Ordered stop names for this leg, INCLUDING origin and destination.
  // stopNames.length - 1 == number of stops passed.
  final List<String> stopNames;

  String get estimatedFareAsString => FareService.fareAsString(fare);

  /// We don't use the originStop.name here because we don't know the preffered
  /// language of the user.
  List<String> stopNamesFromTo(String startName, String destName) {
    // Throw out all stops before the start one
    final tripStart = stopNames.skipWhile((name) => name != startName).toList();
    final indexOfDest = tripStart.indexOf(destName);
    // Invalid destination name
    if (indexOfDest < 0) return [];

    // Take all stops after start one (including it) until destination (including it)
    return tripStart.take(indexOfDest + 1).toList();
  }

  BusLeg({
    required this.routeName,
    required this.departureDateTime,
    required this.arrivalDateTime,
    required this.estimatedDuration,
    required this.stopNames,
    required this.originStop,
    required this.destinationStop,
    required this.fare,
    this.points,
    this.safeDuration,
  });

  BusLeg copyWith({
    String? routeName,
    DateTime? departureDateTime,
    DateTime? arrivalDateTime,
    int? estimatedDuration,
    double? fare,
    List<String>? stopNames,
    Stop? originStop,
    Stop? destinationStop,
    List<LatLng>? points,
    int? safeDuration,
  }) {
    return BusLeg(
      routeName: routeName ?? this.routeName,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      arrivalDateTime: arrivalDateTime ?? this.arrivalDateTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      fare: fare ?? this.fare,
      stopNames: stopNames ?? this.stopNames,
      originStop: originStop ?? this.originStop,
      destinationStop: destinationStop ?? this.destinationStop,
      points: points ?? this.points,
      safeDuration: safeDuration ?? this.safeDuration,
    );
  }
}

/// This class is used for the actual bus trip and must not be
/// confused with the Trip class, which is a generic class to hold basic info
class BusTrip {
  List<LatLng>? points;
  int? safeDuration; // seconds, from OSRM

  final bool isStartAlsoOrigin;

  // Ordered legs of the journey. length == 1 for a direct trip,
  // length >= 2 for any number of transfers.
  final List<BusLeg> legs;

  // Holds the total of all the legs' fares
  double totalFare = -1;

  BusTrip({required this.isStartAlsoOrigin, required this.legs})
    : assert(legs.isNotEmpty, 'BusTrip must have at least one leg') {
    // Will remain -1 if there are no legs (pure walking trip)
    totalFare = legs.fold(0, (sum, leg) => sum + leg.fare);
    // Create the points by combining all the legs
    points = legs.fold(
      <LatLng>[],
      (list, leg) => list ?? <LatLng>[] + (leg.points ?? []),
    );
    // Create the safeDuration combining all the legs again
    safeDuration = legs.fold(
      0,
      (sum, leg) => sum ?? 0 + (leg.safeDuration ?? 0),
    );
  }

  // ---- Convenience getters ----
  bool get isTransfer => legs.length > 1;

  int get transferCount => legs.length - 1;

  DateTime get startDepartureDateTime => legs.first.departureDateTime;

  DateTime get destArrivalDateTime => legs.last.arrivalDateTime;

  /// Sum of riding time across all legs (does NOT include transfer wait time).
  int get estimatedDuration =>
      legs.fold(0, (sum, leg) => sum + leg.estimatedDuration);

  double get totalWaitTime => List.generate(
    legs.length - 1,
    (i) => i,
  ).fold(0, (sum, legIndex) => sum + waitTimeAfterLeg(legIndex).inSeconds);

  String get estimatedFareAsString => FareService.fareAsString(totalFare);

  /// Wait time between leg[i] and leg[i+1], keyed by transfer index (0-based).
  Duration waitTimeAfterLeg(int legIndex) {
    if (legIndex < 0 || legIndex >= legs.length - 1) return Duration.zero;
    return legs[legIndex + 1].departureDateTime.difference(
      legs[legIndex].arrivalDateTime,
    );
  }

  BusTrip copyWith({
    List<LatLng>? points,
    int? safeDuration,
    bool? isStartAlsoOrigin,
    List<BusLeg>? legs,
  }) {
    return BusTrip(
        isStartAlsoOrigin: isStartAlsoOrigin ?? this.isStartAlsoOrigin,
        legs: legs ?? this.legs,
      )
      ..points = points ?? this.points
      ..safeDuration = safeDuration ?? this.safeDuration;
  }
}
