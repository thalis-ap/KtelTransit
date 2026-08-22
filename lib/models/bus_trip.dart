import 'package:latlong2/latlong.dart';

/// A single bus ride on one route, from one stop to another, with no
/// transfers in between. A BusTrip with a transfer is just 2+ of these.
class BusLeg {
  final String routeName;
  final String originStopName;
  final String destinationStopName;
  final DateTime departureDateTime;
  final DateTime arrivalDateTime;
  final int estimatedDuration; // seconds, from stop_times.txt

  // Ordered stop names for this leg, INCLUDING origin and destination.
  // stopNames.length - 1 == number of stops passed.
  final List<String> stopNames;

  BusLeg({
    required this.routeName,
    required this.originStopName,
    required this.destinationStopName,
    required this.departureDateTime,
    required this.arrivalDateTime,
    required this.estimatedDuration,
    required this.stopNames,
  });

  BusLeg copyWith({
    String? routeName,
    String? originStopName,
    String? destinationStopName,
    DateTime? departureDateTime,
    DateTime? arrivalDateTime,
    int? estimatedDuration,
    List<String>? stopNames,
  }) {
    return BusLeg(
      routeName: routeName ?? this.routeName,
      originStopName: originStopName ?? this.originStopName,
      destinationStopName: destinationStopName ?? this.destinationStopName,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      arrivalDateTime: arrivalDateTime ?? this.arrivalDateTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      stopNames: stopNames ?? this.stopNames,
    );
  }
}

/// This class is used for the actual osrm-computed trip and must not be
/// confused with the Trip class, which is a generic class to hold basic info
class BusTrip {
  final List<LatLng>? points;
  final int? safeDuration; // seconds, from OSRM

  final bool isStartAlsoOrigin;

  // Ordered legs of the journey. length == 1 for a direct trip,
  // length >= 2 for any number of transfers.
  final List<BusLeg> legs;

  BusTrip({
    required this.isStartAlsoOrigin,
    required this.legs,
    this.points,
    this.safeDuration,
  }) : assert(legs.isNotEmpty, 'BusTrip must have at least one leg');

  // ---- Convenience getters so most existing call sites don't need to change ----

  bool get isTransfer => legs.length > 1;
  int get transferCount => legs.length - 1;

  String get originStopName => legs.first.originStopName;
  String get destinationStopName => legs.last.destinationStopName;
  DateTime get startDepartureDateTime => legs.first.departureDateTime;
  DateTime get destArrivalDateTime => legs.last.arrivalDateTime;

  /// Sum of riding time across all legs (does NOT include transfer wait time).
  int get estimatedDuration =>
      legs.fold(0, (sum, leg) => sum + leg.estimatedDuration);

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
      points: points ?? this.points,
      safeDuration: safeDuration ?? this.safeDuration,
      isStartAlsoOrigin: isStartAlsoOrigin ?? this.isStartAlsoOrigin,
      legs: legs ?? this.legs,
    );
  }
}