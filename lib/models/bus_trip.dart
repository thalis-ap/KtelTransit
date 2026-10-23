import 'dart:ui';
import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/services/fare_catalog_service.dart';
import 'package:ktel_transit/utilities/fare_utils.dart';
import 'package:latlong2/latlong.dart';

import '../services/fare_service.dart';
import '../theme/app_theme.dart';
import 'fare_leg_rules.dart';
import 'fare_transfer_rules.dart';

/// A single bus ride on one route, from one stop to another, with no
/// transfers in between. A BusTrip with a transfer is just 2+ of these.
class BusLeg {
  final List<LatLng>? points;
  final int? safeDuration; // seconds, from OSRM

  final String routeName;
  final DateTime departureDateTime;
  final DateTime arrivalDateTime;
  final int estimatedDuration; // seconds, from stop_times.txt

  /// All possible fare options for this leg (across all rider categories).
  /// Used to populate the fare breakdown modal.
  final List<FareProductOption> fareOptions;

  // This is the fare of the default rider category that appears before category selection
  final double? defaultFare;

  final Stop originStop;
  final Stop destinationStop;

  /// This only refers to the trip itself being accessible regardless of the stops
  final WheelchairBoarding wheelchairBoarding;

  // Ordered stop names for this leg, INCLUDING origin and destination.
  // stopNames.length - 1 == number of stops passed.
  final List<String> stopNames;

  /// Refers to gtfs' route_color, but we need it for each individual leg
  final Color legColor;

  /// This is acquired from shapes.txt file and contains points for this trip
  /// that must be crossed. They should be given to OSRM to compute the route
  /// that satisfies passing from all of them
  final List<LatLng> passingPoints;

  String get estimatedFareAsString => FareFormat.fareAsString(defaultFare);

  /// This indicates if the leg as a whole is accessible. This means that
  /// both origin stop and destination stop must be accessible while the trip
  /// is accessible as well. The latter means that the particular trip/bus is
  /// accessible as per trips.txt
  WheelchairBoarding get isWheelchairAccessible =>
      wheelchairBoarding &
      (originStop.wheelchairBoarding & destinationStop.wheelchairBoarding);

  /// We don't use the originStop.name here because we don't know the preferred
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
    required this.fareOptions,
    required this.defaultFare,
    required this.passingPoints,
    this.points,
    this.safeDuration,
    this.wheelchairBoarding = WheelchairBoarding.unknown,
    this.legColor = AppTheme.blueish,
  });

  BusLeg copyWith({
    String? routeName,
    DateTime? departureDateTime,
    DateTime? arrivalDateTime,
    int? estimatedDuration,
    List<FareProductOption>? fareOptions,
    double? defaultFare,
    List<String>? stopNames,
    Stop? originStop,
    Stop? destinationStop,
    List<LatLng>? passingPoints,
    List<LatLng>? points,
    int? safeDuration,
    WheelchairBoarding? wheelchairBoarding,
    Color? legColor,
  }) {
    return BusLeg(
      routeName: routeName ?? this.routeName,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      arrivalDateTime: arrivalDateTime ?? this.arrivalDateTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      fareOptions: fareOptions ?? this.fareOptions,
      defaultFare: defaultFare ?? this.defaultFare,
      stopNames: stopNames ?? this.stopNames,
      originStop: originStop ?? this.originStop,
      destinationStop: destinationStop ?? this.destinationStop,
      passingPoints: passingPoints ?? this.passingPoints,
      points: points ?? this.points,
      safeDuration: safeDuration ?? this.safeDuration,
      wheelchairBoarding: wheelchairBoarding ?? this.wheelchairBoarding,
      legColor: legColor ?? this.legColor,
    );
  }
}

/// This class is used for the actual bus trip and must not be
/// confused with the Trip class, which is a generic class to hold basic info
class BusTrip {
  final bool isStartAlsoOrigin;

  // Ordered legs of the journey. length == 1 for a direct trip,
  // length >= 2 for any number of transfers.
  final List<BusLeg> legs;

  // Everything needed to compute the unified options, but not the options
  // themselves. Kept private so the public API is just the getter below.
  final Map<String, List<FareLegRule>> _legRulesByProductId;
  final List<FareTransferRule> _transferRules;

  List<FareProductOption>? _unifiedOptionsCache;

  BusTrip({
    required this.isStartAlsoOrigin,
    required this.legs,
    Map<String, List<FareLegRule>>? legRulesByProductId,
    List<FareTransferRule>? transferRules,
  }) : assert(legs.isNotEmpty, 'BusTrip must have at least one leg'),
       _legRulesByProductId = legRulesByProductId ?? const {},
       _transferRules = transferRules ?? const <FareTransferRule>[] {
    totalDefaultFare = legs.fold(
      0.0,
      (sum, leg) => (sum ?? 0.0) + (leg.defaultFare ?? 0.0),
    );
  }

  /// Products that pay for the whole trip in one purchase.
  /// Computed on first access, then cached. Safe to call from build().
  List<FareProductOption> get unifiedFareOptions =>
      _unifiedOptionsCache ??= _computeUnifiedOptions();

  List<FareProductOption> _computeUnifiedOptions() {
    if (_legRulesByProductId.isEmpty) {
      return const <FareProductOption>[]; // invalid feed, no rules
    }
    return FareService.getOptionsForTrip(
      perLegOptions: [for (final leg in legs) leg.fareOptions],
      legRulesByProductId: _legRulesByProductId,
      transferRules: _transferRules,
    );
  }

  // Holds the total of all the legs' fares
  double? totalDefaultFare;

  // Holds the amount of the cheapest available product that covers the whole trip
  double? get cheapestFare => unifiedFareOptions.firstOrNull?.product.amount;

  // Get the safeDuration by combining all the legs again
  int get safeDuration =>
      legs.fold(0, (sum, leg) => sum + (leg.safeDuration ?? 0));

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

  String get estimatedFareAsString => FareFormat.fareAsString(totalDefaultFare);

  /// This indicates if the whole trip is wheelchair accessible, meaning all legs
  /// are wheelchair accessible. (See BusLeg.isWheelchairAccessible for more)
  WheelchairBoarding get isWheelchairAccessible => legs.fold(
    WheelchairBoarding.accessible,
    (sum, leg) => sum & leg.isWheelchairAccessible,
  );

  /// Wait time between leg[i] and leg[i+1], keyed by transfer index (0-based).
  Duration waitTimeAfterLeg(int legIndex) {
    if (legIndex < 0 || legIndex >= legs.length - 1) return Duration.zero;
    return legs[legIndex + 1].departureDateTime.difference(
      legs[legIndex].arrivalDateTime,
    );
  }

  BusTrip copyWith({
    bool? isStartAlsoOrigin,
    List<BusLeg>? legs,
    Map<String, List<FareLegRule>>? legRulesByProductId,
    List<FareTransferRule>? transferRules,
  }) {
    return BusTrip(
      isStartAlsoOrigin: isStartAlsoOrigin ?? this.isStartAlsoOrigin,
      legs: legs ?? this.legs,
      legRulesByProductId: legRulesByProductId ?? _legRulesByProductId,
      transferRules: transferRules ?? _transferRules,
    );
  }
}
