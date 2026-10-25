import 'package:ktel_transit/models/gtfs/agency/agency.dart';
import 'package:ktel_transit/models/gtfs/calendars/calendar.dart';
import 'package:ktel_transit/models/extras/departure.dart';
import 'package:ktel_transit/models/routing/bus_trip.dart';
import 'package:ktel_transit/models/gtfs/fares/fare_media.dart';
import 'package:ktel_transit/models/gtfs/fares/fare_product.dart';
import 'package:ktel_transit/models/gtfs/fares/rider_category.dart';
import 'package:ktel_transit/models/gtfs/stops/stop.dart';
import 'package:ktel_transit/models/gtfs/trips/trip.dart';
import 'package:ktel_transit/models/gtfs/routes/route.dart';
import 'package:ktel_transit/models/gtfs/stops/stop_time.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/utilities/color_utils.dart';
import 'package:ktel_transit/utilities/time_utils.dart';
import 'package:latlong2/latlong.dart';
import '../models/gtfs/calendars/calendar_date.dart';
import '../models/gtfs/fares/fare_leg_rules.dart';
import '../models/gtfs/fares/fare_transfer_rules.dart';
import '../models/gtfs/networks/network.dart';
import '../models/gtfs/networks/route_network.dart';
import '../models/gtfs/shapes/shape.dart';
import '../services/gtfs/fares/fare_service.dart';

/// Pure data container for GTFS data.
/// All strings are already translated. No language code is needed.
/// This class does NOT load data; use GtfsLocal to populate it.
class GtfsRepository {
  static final GtfsRepository _instance = GtfsRepository._internal();

  factory GtfsRepository() => _instance;

  GtfsRepository._internal();

  // ---- Data Lists (already translated) ----
  List<Agency> agencies = [];
  List<Stop> stops = [];
  List<Route> routes = [];
  List<Trip> trips = [];
  List<StopTime> stopTimes = [];
  List<Shape> shapes = [];
  List<Calendar> calendars = [];
  List<CalendarDate> calendarDates = [];
  List<FareMedia> fareMedia = [];
  List<RiderCategory> riderCategories = [];
  List<FareProduct> fareProducts = [];
  List<Network> networks = [];
  List<RouteNetwork> routeNetworks = [];
  List<FareLegRule> fareLegRules = [];
  List<FareTransferRule> fareTransferRules = [];

  // ---- Indexes ----
  Map<String, List<StopTime>> _stopTimesByStopId = {};
  Map<String, List<StopTime>> _stopTimesByTripId = {};
  Map<String, Trip> _tripsById = {};
  Map<String, Route> _routesById = {};
  Map<String, Stop> _stopsById = {};
  Map<String, List<Shape>> _shapesById = {};
  Map<int, List<CalendarDate>> _calendarDatesByDate = {};
  Map<String, FareMedia> _fareMediaById = {};
  Map<String, RiderCategory> _riderCategoriesById = {};
  Map<String, Network> _networksById = {};
  Map<String, List<Network>> _networksByRouteId = {};
  Map<String, List<Route>> _routesByNetworkId = {};
  Map<String, List<FareLegRule>> _fareLegRulesByProductId = {};
  Map<String, List<FareLegRule>> _fareLegRulesByLegGroupId = {};
  Map<String, List<FareLegRule>> _fareLegRulesByNetworkId = {};
  Map<String, List<FareTransferRule>> _fareTransferRulesByFromLegGroupId = {};
  Set<String> _fareProductIdsWithoutNetwork = {};
  Map<String, Set<String>> _fareProductIdsByRouteId = {};

  /// Clears all data and indexes.
  void clear() {
    agencies.clear();
    stops.clear();
    routes.clear();
    trips.clear();
    stopTimes.clear();
    calendars.clear();
    calendarDates.clear();
    shapes.clear();
    fareMedia.clear();
    riderCategories.clear();
    fareProducts.clear();
    networks.clear();
    routeNetworks.clear();
    fareLegRules.clear();
    fareTransferRules.clear();

    _stopTimesByStopId = {};
    _stopTimesByTripId = {};
    _tripsById = {};
    _routesById = {};
    _stopsById = {};
    _calendarDatesByDate = {};
    _shapesById = {};
    _fareMediaById = {};
    _riderCategoriesById = {};
    _networksById = {};
    _networksByRouteId = {};
    _routesByNetworkId = {};
    _fareLegRulesByProductId = {};
    _fareLegRulesByLegGroupId = {};
    _fareLegRulesByNetworkId = {};
    _fareTransferRulesByFromLegGroupId = {};
    _fareProductIdsWithoutNetwork = {};
    _fareProductIdsByRouteId = {};
  }

  /// Builds indexes from current data.
  /// Must be called after data is loaded.
  void buildIndexes() {
    // Empty the maps before populating them with new data)
    _stopTimesByStopId = {};
    _stopTimesByTripId = {};
    _calendarDatesByDate = {};
    _shapesById = {};

    for (final st in stopTimes) {
      _stopTimesByStopId.putIfAbsent(st.stopId, () => []).add(st);
      _stopTimesByTripId.putIfAbsent(st.tripId, () => []).add(st);
    }
    _tripsById = {for (final t in trips) t.tripId: t};
    _routesById = {for (final r in routes) r.routeId: r};
    _stopsById = {for (final s in stops) s.stopId: s};

    for (final s in shapes) {
      _shapesById.putIfAbsent(s.shapeId, () => []).add(s);
    }

    for (final cd in calendarDates) {
      final int dateInt = int.tryParse(cd.date) ?? 0;
      if (dateInt > 0) {
        _calendarDatesByDate.putIfAbsent(dateInt, () => []).add(cd);
      }
    }

    _fareMediaById = {for (final m in fareMedia) m.fareMediaId: m};
    _riderCategoriesById = {
      for (final c in riderCategories) c.riderCategoryId: c,
    };

    _networksById = {for (final n in networks) n.networkId: n};

    // Resolve the route↔network join in both directions. Rows whose route or
    // network doesn't exist are silently dropped — a dangling reference is a
    // data-quality issue, not a reason to fail the whole load.
    _networksByRouteId = {};
    _routesByNetworkId = {};
    for (final rn in routeNetworks) {
      final network = _networksById[rn.networkId];
      final route = _routesById[rn.routeId];
      if (network == null || route == null) continue;
      _networksByRouteId.putIfAbsent(rn.routeId, () => []).add(network);
      _routesByNetworkId.putIfAbsent(rn.networkId, () => []).add(route);
    }

    _fareLegRulesByProductId = {};
    _fareLegRulesByLegGroupId = {};
    _fareLegRulesByNetworkId = {};

    for (final rule in fareLegRules) {
      _fareLegRulesByProductId
          .putIfAbsent(rule.fareProductId, () => [])
          .add(rule);
      final groupId = rule.legGroupId;
      if (groupId != null) {
        _fareLegRulesByLegGroupId.putIfAbsent(groupId, () => []).add(rule);
      }
      final nid = rule.networkId;
      if (nid != null) {
        _fareLegRulesByNetworkId.putIfAbsent(nid, () => []).add(rule);
      } else {
        _fareProductIdsWithoutNetwork.add(rule.fareProductId);
      }
    }

    // Resolve which fare products can be used on each route. A rule that
    // names one of the route's networks wins; otherwise the route falls back
    // to the rules that don't name any network.
    for (final route in routes) {
      final explicit = <String>{};
      for (final network in getNetworksForRoute(route.routeId)) {
        explicit.addAll(
          (_fareLegRulesByNetworkId[network.networkId] ?? const []).map(
                (r) => r.fareProductId,
          ),
        );
      }
      _fareProductIdsByRouteId[route.routeId] = explicit.isNotEmpty
          ? explicit
          : _fareProductIdsWithoutNetwork;
    }

    _fareTransferRulesByFromLegGroupId = {};
    for (final rule in fareTransferRules) {
      final groupId = rule.fromLegGroupId;
      if (groupId != null) {
        _fareTransferRulesByFromLegGroupId
            .putIfAbsent(groupId, () => [])
            .add(rule);
      }
    }
  }

  // ---- Query Methods ----
  List<Departure> getDeparturesForStop(
    String departureStopId, {
    DateTime? selectedTime,
  }) {
    final DateTime target = selectedTime ?? DateTime.now();

    List<String> validServiceIds = _getServiceIds(target);
    int startMinutes = target.hour * 60 + target.minute;

    if (target.hour < 4) {
      startMinutes += 24 * 60;
      final prevDay = target.subtract(const Duration(days: 1));
      validServiceIds = _getServiceIds(prevDay);
    }

    final Stop? departureStop = _stopsById[departureStopId];
    if (departureStop == null) return [];

    List<StopTime> times = (_stopTimesByStopId[departureStopId] ?? []).where((
      st,
    ) {
      return TimeFormat.gtfsTimeToMinutes(st.arrivalTime) >= startMinutes;
    }).toList();
    times.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    final List<Departure> results = [];
    for (StopTime st in times) {
      try {
        final Trip? trip = _tripsById[st.tripId];
        if (trip == null) continue;
        if (!validServiceIds.contains(trip.serviceId)) continue;

        final Route? route = _routesById[trip.routeId];
        if (route == null) continue;
        final String routeName = trip.getDisplayName(
          route.longName,
        ); // longName is already translated

        final List<StopTime> allTripsStopTimes = List.of(
          _stopTimesByTripId[trip.tripId] ?? [],
        );
        allTripsStopTimes.sort(
          (a, b) => a.stopSequence.compareTo(b.stopSequence),
        );

        final StopTime originStopTime = allTripsStopTimes.first;
        final StopTime destinationStopTime = allTripsStopTimes.last;
        final StopTime departureStopTime = allTripsStopTimes.firstWhere(
          (s) => s.stopId == departureStopId,
        );

        final Stop? originStop = _stopsById[originStopTime.stopId];
        final Stop? destinationStop = _stopsById[destinationStopTime.stopId];
        if (originStop == null || destinationStop == null) continue;

        results.add(
          Departure(
            originStop: originStop,
            departureStop: departureStop,
            destinationStop: destinationStop,
            originDepartureTime: TimeFormat.gtfsTimeToDateTime(
              target,
              originStopTime.departureTime,
            ),
            departureTime: TimeFormat.gtfsTimeToDateTime(
              target,
              departureStopTime.arrivalTime,
            ),
            routeName: routeName,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    results.sort(
      (a, b) => a.originDepartureTime.compareTo(b.originDepartureTime),
    );
    return results;
  }

  List<BusTrip> findAllTripsBetween(
    String startStopId,
    String destStopId, {
    DateTime? selectedTime,
    int maxDaysToSearch = 7,
  }) {
    final DateTime startDate = selectedTime ?? DateTime.now();
    List<BusTrip> allTrips = [];

    for (int dayOffset = 0; dayOffset <= maxDaysToSearch; dayOffset++) {
      final DateTime date = dayOffset == 0
          ? startDate
          : DateTime(
              startDate.year,
              startDate.month,
              startDate.day + dayOffset,
              4,
              0,
            );

      final List<BusTrip> dailyTrips = _findTripsForDate(
        startStopId,
        destStopId,
        date,
      );
      allTrips.addAll(dailyTrips);
    }

    return allTrips;
  }

  /// Searches for trips between two stops on a specific date.
  /// Returns an empty list if no trips are found.
  List<BusTrip> _findTripsForDate(
    String startStopId,
    String destStopId,
    DateTime date,
  ) {
    // Get service IDs valid on this date
    List<String> validServiceIds = _getServiceIds(date);

    // Get start minutes, handling early-morning (before 4 AM) as previous day
    int startMinutes = date.hour * 60 + date.minute;
    DateTime effectiveDate = date;
    if (date.hour < 4) {
      startMinutes += 24 * 60;
      effectiveDate = date.subtract(const Duration(days: 1));
      validServiceIds = _getServiceIds(effectiveDate);
    }

    Stop startStop = _stopsById[startStopId]!;
    Stop destStop = _stopsById[destStopId]!;

    // Find all departures from start stop after the given minute
    List<StopTime> startTimes = (_stopTimesByStopId[startStopId] ?? [])
        .where(
          (st) =>
              TimeFormat.gtfsTimeToMinutes(st.departureTime) >= startMinutes,
        )
        .toList();
    startTimes.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    List<BusTrip> dailyTrips = [];

    // Direct trips
    for (StopTime stStart in startTimes) {
      try {
        final Trip? trip = _tripsById[stStart.tripId];
        if (trip == null) continue;
        if (!validServiceIds.contains(trip.serviceId)) continue;

        // If we can't find a shape to give us the passing points just default
        // to 2 points: start and dest. Not being able to find a shape means
        // that there is no shape provided for this route, thus we will guess
        // the map route using the starting and destination points only.
        // See BusServide.getCompleteLeg() for more.
        final List<LatLng> passingPoints =
            _shapesById[trip.shapeId]
                ?.map((s) => LatLng(s.latitude, s.longitude))
                .toList() ??
            [
              LatLng(startStop.latitude, startStop.longitude),
              LatLng(destStop.latitude, destStop.longitude),
            ];

        final List<StopTime> destTimes = (_stopTimesByTripId[trip.tripId] ?? [])
            .where((st) => st.stopId == destStopId)
            .toList();
        if (destTimes.isEmpty) continue;

        final StopTime stDest = destTimes.first;
        if (stDest.stopSequence <= stStart.stopSequence) continue;

        final int durationSecs = TimeFormat.gtfsTimesToDiffSeconds(
          stDest.arrivalTime,
          stStart.departureTime,
        );

        final Route? route = _routesById[trip.routeId];
        if (route == null) continue;

        String displayName = trip.getDisplayName(route.longName);

        final List<StopTime> allTripStops = List.of(
          _stopTimesByTripId[trip.tripId] ?? [],
        );
        allTripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

        final stopNames = _getStopNamesForTrip(trip.tripId);

        // Fetch all possible fare options for this leg
        final fareOptions = FareService.getOptionsForLeg(
          allowedProductIds: getFareProductIdsForRoute(route.routeId),
          originStopId: startStopId,
          destinationStopId: destStopId,
          allProducts: fareProducts,
          allMedia: fareMedia,
        );

        // Pick the "Standard/Default" fare for summary price
        final defaultFare = fareOptions
            .where(
              (o) =>
                  o.product.riderCategoryId ==
                      defaultRiderCategory?.riderCategoryId ||
                  o.product.isValidForAnyRiderCategory,
            )
            .firstOrNull
            ?.product
            .amount;

        final leg = BusLeg(
          routeName: displayName,
          departureDateTime: TimeFormat.gtfsTimeToDateTime(
            date,
            stStart.departureTime,
          ),
          arrivalDateTime: TimeFormat.gtfsTimeToDateTime(
            date,
            stDest.arrivalTime,
          ),
          estimatedDuration: durationSecs,
          fareOptions: fareOptions,
          defaultFare: defaultFare,
          stopNames: stopNames,
          originStop: startStop,
          destinationStop: destStop,
          passingPoints: passingPoints,
          wheelchairBoarding: trip.wheelchairBoarding,
          legColor: ColorUtils.fromHex(route.routeColor) ?? AppTheme.blueish,
        );

        dailyTrips.add(
          BusTrip(
            isStartAlsoOrigin: true,
            legs: [leg],
            legRulesByProductId: _fareLegRulesByProductId,
            transferRules: fareTransferRules,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    // Transfer trips (only if no direct trips found)
    if (dailyTrips.isEmpty) {
      for (StopTime stStart in startTimes) {
        try {
          final Trip? tripA = _tripsById[stStart.tripId];
          if (tripA == null) continue;
          if (!validServiceIds.contains(tripA.serviceId)) continue;

          final List<StopTime> tripAStops =
              (_stopTimesByTripId[tripA.tripId] ?? [])
                  .where((st) => st.stopSequence > stStart.stopSequence)
                  .toList();
          tripAStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

          for (StopTime transferA in tripAStops) {
            final int tArrivalMins = TimeFormat.gtfsTimeToMinutes(
              transferA.arrivalTime,
            );

            List<StopTime> potentialLeg2 =
                (_stopTimesByStopId[transferA.stopId] ?? []).where((st) {
                  final tDepartMins = TimeFormat.gtfsTimeToMinutes(
                    st.departureTime,
                  );
                  return tDepartMins >= tArrivalMins &&
                      tDepartMins <= tArrivalMins + 60 * 24;
                }).toList();

            for (StopTime stTransB in potentialLeg2) {
              final Trip? tripB = _tripsById[stTransB.tripId];
              if (tripB == null) continue;
              if (!validServiceIds.contains(tripB.serviceId)) continue;
              if (tripA.tripId == tripB.tripId) continue;

              final List<StopTime> destTimes =
                  (_stopTimesByTripId[tripB.tripId] ?? [])
                      .where(
                        (st) =>
                            st.stopId == destStopId &&
                            st.stopSequence > stTransB.stopSequence,
                      )
                      .toList();
              if (destTimes.isEmpty) continue;

              final StopTime stDest = destTimes.first;

              final Route? routeA = _routesById[tripA.routeId];
              final Route? routeB = _routesById[tripB.routeId];
              if (routeA == null || routeB == null) continue;

              final Stop transferStop = _stopsById[transferA.stopId]!;

              String rAName = tripA.getDisplayName(routeA.longName);
              String rBName = tripB.getDisplayName(routeB.longName);

              final List<LatLng> passingPointsA =
                  _shapesById[tripA.shapeId]
                      ?.map((s) => LatLng(s.latitude, s.longitude))
                      .toList() ??
                  [
                    LatLng(startStop.latitude, startStop.longitude),
                    LatLng(transferStop.latitude, transferStop.longitude),
                  ];

              final List<LatLng> passingPointsB =
                  _shapesById[tripB.shapeId]
                      ?.map((s) => LatLng(s.latitude, s.longitude))
                      .toList() ??
                  [
                    LatLng(transferStop.latitude, transferStop.longitude),
                    LatLng(destStop.latitude, destStop.longitude),
                  ];

              final int durationLeg1 = TimeFormat.gtfsTimesToDiffSeconds(
                transferA.arrivalTime,
                stStart.departureTime,
              );
              final int durationLeg2 = TimeFormat.gtfsTimesToDiffSeconds(
                stDest.arrivalTime,
                stTransB.departureTime,
              );

              // We have transfer route, pass secondRouteName
              final stopNamesA = _getStopNamesForTrip(tripA.tripId);
              final stopNamesB = _getStopNamesForTrip(tripB.tripId);

              // Fetch all possible fare options for both legs
              final fareOptions1 = FareService.getOptionsForLeg(
                allowedProductIds: getFareProductIdsForRoute(routeA.routeId),
                originStopId: startStopId,
                destinationStopId: transferA.stopId,
                allProducts: fareProducts,
                allMedia: fareMedia,
              );
              final fareOptions2 = FareService.getOptionsForLeg(
                allowedProductIds: getFareProductIdsForRoute(routeB.routeId),
                originStopId: transferA.stopId,
                destinationStopId: destStopId,
                allProducts: fareProducts,
                allMedia: fareMedia,
              );

              // Pick the "Standard/Default" fares for summary price
              final defaultFare1 = fareOptions1
                  .where(
                    (o) =>
                        o.product.riderCategoryId ==
                            defaultRiderCategory?.riderCategoryId ||
                        o.product.isValidForAnyRiderCategory,
                  )
                  .firstOrNull
                  ?.product
                  .amount;
              final defaultFare2 = fareOptions2
                  .where(
                    (o) =>
                        o.product.riderCategoryId ==
                            defaultRiderCategory?.riderCategoryId ||
                        o.product.isValidForAnyRiderCategory,
                  )
                  .firstOrNull
                  ?.product
                  .amount;

              final leg1 = BusLeg(
                routeName: rAName,
                departureDateTime: TimeFormat.gtfsTimeToDateTime(
                  date,
                  stStart.departureTime,
                ),
                arrivalDateTime: TimeFormat.gtfsTimeToDateTime(
                  date,
                  transferA.arrivalTime,
                ),
                estimatedDuration: durationLeg1,
                fareOptions: fareOptions1,
                defaultFare: defaultFare1,
                stopNames: stopNamesA,
                originStop: startStop,
                destinationStop: transferStop,
                passingPoints: passingPointsA,
                wheelchairBoarding: tripA.wheelchairBoarding,
                legColor:
                    ColorUtils.fromHex(routeA.routeColor) ?? AppTheme.blueish,
              );

              final leg2 = BusLeg(
                routeName: rBName,
                departureDateTime: TimeFormat.gtfsTimeToDateTime(
                  date,
                  stTransB.departureTime,
                ),
                arrivalDateTime: TimeFormat.gtfsTimeToDateTime(
                  date,
                  stDest.arrivalTime,
                ),
                estimatedDuration: durationLeg2,
                fareOptions: fareOptions2,
                defaultFare: defaultFare2,
                stopNames: stopNamesB,
                originStop: transferStop,
                destinationStop: destStop,
                passingPoints: passingPointsB,
                wheelchairBoarding: tripB.wheelchairBoarding,
                legColor:
                    ColorUtils.fromHex(routeB.routeColor) ?? AppTheme.blueish,
              );

              dailyTrips.add(
                BusTrip(
                  isStartAlsoOrigin: true,
                  legs: [leg1, leg2],
                  legRulesByProductId: _fareLegRulesByProductId,
                  transferRules: fareTransferRules,
                ),
              );
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    dailyTrips.sort((a, b) {
      return a.startDepartureDateTime.compareTo(b.startDepartureDateTime);
    });

    return dailyTrips;
  }

  /// True when the current region provides any fare products at all
  bool get hasFareProducts => fareProducts.isNotEmpty;

  FareMedia? getFareMedia(String fareMediaId) => _fareMediaById[fareMediaId];

  RiderCategory? getRiderCategory(String riderCategoryId) =>
      _riderCategoriesById[riderCategoryId];

  /// The category that should be preselected in the UI: the one marked as
  /// default, otherwise the first one, otherwise null.
  RiderCategory? get defaultRiderCategory =>
      riderCategories.where((c) => c.isDefault).firstOrNull ??
      riderCategories.firstOrNull;

  // ---- Network lookups ----
  Network? getNetwork(String networkId) => _networksById[networkId];

  /// All networks the route belongs to. Empty for regions that haven't adopted
  /// networks.txt (the common case for simple KTEL feeds).
  List<Network> getNetworksForRoute(String routeId) =>
      _networksByRouteId[routeId] ?? const [];

  /// All routes that belong to a network. Empty when the network doesn't exist
  /// or has no routes registered in route_networks.txt.
  List<Route> getRoutesForNetwork(String networkId) =>
      _routesByNetworkId[networkId] ?? const [];

  // ---- Fare rule lookups ----
  List<FareLegRule> getFareLegRulesForProduct(String fareProductId) =>
      _fareLegRulesByProductId[fareProductId] ?? const [];

  List<FareLegRule> getFareLegRulesForLegGroup(String legGroupId) =>
      _fareLegRulesByLegGroupId[legGroupId] ?? const [];

  List<FareLegRule> getFareLegRulesForNetwork(String networkId) =>
      _fareLegRulesByNetworkId[networkId] ?? const [];

  List<FareTransferRule> getFareTransferRulesForFromLegGroup(
    String legGroupId,
  ) => _fareTransferRulesByFromLegGroupId[legGroupId] ?? const [];

  /// Fare product ids that can be used to ride [routeId]. Null when the region
  /// has no leg rules at all, meaning "don't filter".
  Set<String>? getFareProductIdsForRoute(String routeId) {
    if (fareLegRules.isEmpty) return null;
    return _fareProductIdsByRouteId[routeId] ?? _fareProductIdsWithoutNetwork;
  }

  /// True when the current region has adopted Fares v2 routing rules (networks
  /// and/or leg rules), as opposed to the simplified product-only model used
  /// by most KTEL feeds.
  bool get hasFareRules => fareLegRules.isNotEmpty || routeNetworks.isNotEmpty;

  // ---- Internal Helpers ----
  List<String> _getStopNamesForTrip(String tripId) {
    final stopTimes = _stopTimesByTripId[tripId] ?? [];
    if (stopTimes.isEmpty) return [];
    final sorted = List<StopTime>.from(stopTimes)
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return sorted.map((st) {
      final stop = _stopsById[st.stopId];
      return stop?.name ?? st.stopId; // name is already translated
    }).toList();
  }

  List<String> _getServiceIds(DateTime targetDateTime) {
    // Changed to a Set to naturally handle duplicates
    final Set<String> activeServiceIds = {};

    final int targetDateInt =
        targetDateTime.year * 10000 +
        targetDateTime.month * 100 +
        targetDateTime.day;

    // Process regular calendar schedules (if any)
    for (final calendar in calendars) {
      try {
        final int startDate = int.parse(calendar.startDate);
        final int endDate = int.parse(calendar.endDate);

        if (targetDateInt < startDate || targetDateInt > endDate) {
          continue;
        }
      } catch (e) {
        continue;
      }

      bool isRunningToday = false;
      switch (targetDateTime.weekday) {
        case DateTime.monday:
          isRunningToday = calendar.monday;
          break;
        case DateTime.tuesday:
          isRunningToday = calendar.tuesday;
          break;
        case DateTime.wednesday:
          isRunningToday = calendar.wednesday;
          break;
        case DateTime.thursday:
          isRunningToday = calendar.thursday;
          break;
        case DateTime.friday:
          isRunningToday = calendar.friday;
          break;
        case DateTime.saturday:
          isRunningToday = calendar.saturday;
          break;
        case DateTime.sunday:
          isRunningToday = calendar.sunday;
          break;
      }

      if (isRunningToday) {
        activeServiceIds.add(calendar.serviceId);
      }
    }

    // Process exceptions for this specific date
    final List<CalendarDate> exceptions =
        _calendarDatesByDate[targetDateInt] ?? [];
    for (final exception in exceptions) {
      if (exception.exceptionType == 1) {
        // Service has been added for this specific date
        activeServiceIds.add(exception.serviceId);
      } else if (exception.exceptionType == 2) {
        // Service has been removed for this specific date
        activeServiceIds.remove(exception.serviceId);
      }
    }

    return activeServiceIds.toList();
  }
}
