import 'package:ktel_transit/models/calendar.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/models/route.dart';
import 'package:ktel_transit/models/stop_time.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import '../models/region.dart';
import '../services/fare_service.dart';

/// Pure data container for GTFS data.
/// All strings are already translated. No language code is needed.
/// This class does NOT load data; use GtfsLocal to populate it.
class GtfsRepository {
  static final GtfsRepository _instance = GtfsRepository._internal();

  factory GtfsRepository() => _instance;

  GtfsRepository._internal();

  // ---- Data Lists (already translated) ----
  List<Stop> stops = [];
  List<Route> routes = [];
  List<Trip> trips = [];
  List<StopTime> stopTimes = [];
  List<Calendar> calendars = [];

  // ---- Indexes ----
  Map<String, List<StopTime>> _stopTimesByStopId = {};
  Map<String, List<StopTime>> _stopTimesByTripId = {};
  Map<String, Trip> _tripsById = {};
  Map<String, Route> _routesById = {};
  Map<String, Stop> _stopsById = {};

  /// Clears all data and indexes.
  void clear() {
    stops.clear();
    routes.clear();
    trips.clear();
    stopTimes.clear();
    calendars.clear();
    _stopTimesByStopId = {};
    _stopTimesByTripId = {};
    _tripsById = {};
    _routesById = {};
    _stopsById = {};
  }

  /// Builds indexes from current data.
  /// Must be called after data is loaded.
  void buildIndexes() {
    _stopTimesByStopId = {};
    _stopTimesByTripId = {};
    for (final st in stopTimes) {
      _stopTimesByStopId.putIfAbsent(st.stopId, () => []).add(st);
      _stopTimesByTripId.putIfAbsent(st.tripId, () => []).add(st);
    }
    _tripsById = {for (final t in trips) t.tripId: t};
    _routesById = {for (final r in routes) r.routeId: r};
    _stopsById = {for (final s in stops) s.stopId: s};
  }

  // ---- Query Methods ----
  List<Departure> getDeparturesForStop(String departureStopId, {
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
        st,) {
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
            route.longName); // longName is already translated

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
          : DateTime(startDate.year, startDate.month, startDate.day + dayOffset, 4, 0);

      final List<BusTrip> dailyTrips = _findTripsForDate(startStopId, destStopId, date);
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
        final double fare = FareService.calculateFare(startStop, destStop);

        final leg = BusLeg(
          routeName: displayName,
          departureDateTime: TimeFormat.gtfsTimeToDateTime(date, stStart.departureTime),
          arrivalDateTime: TimeFormat.gtfsTimeToDateTime(date, stDest.arrivalTime),
          estimatedDuration: durationSecs,
          fare: fare,
          stopNames: stopNames,
          originStop: startStop,
          destinationStop: destStop,
        );

        dailyTrips.add(BusTrip(
          isStartAlsoOrigin: true,
          legs: [leg],
        ));
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

              String rAName = tripA.getDisplayName(
                routeA.longName,
              );
              String rBName = tripB.getDisplayName(
                routeB.longName,
              );

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

              final double fare1 = FareService.calculateFare(startStop, transferStop);
              final double fare2 = FareService.calculateFare(transferStop, destStop);

              final leg1 = BusLeg(
                routeName: rAName,
                departureDateTime: TimeFormat.gtfsTimeToDateTime(date, stStart.departureTime),
                arrivalDateTime: TimeFormat.gtfsTimeToDateTime(date, transferA.arrivalTime),
                estimatedDuration: durationLeg1,
                fare: fare1,
                stopNames: stopNamesA,
                originStop: startStop,
                destinationStop: transferStop,
              );


              final leg2 = BusLeg(
                routeName: rBName,
                departureDateTime: TimeFormat.gtfsTimeToDateTime(date, stTransB.departureTime),
                arrivalDateTime: TimeFormat.gtfsTimeToDateTime(date, stDest.arrivalTime),
                estimatedDuration: durationLeg2,
                fare: fare2,
                stopNames: stopNamesB,
                originStop: transferStop,
                destinationStop: destStop,
              );

              dailyTrips.add(BusTrip(
                isStartAlsoOrigin: true,
                legs: [leg1, leg2],
              ));
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
    final List<String> activeServiceIds = [];

    final int targetDateInt =
        targetDateTime.year * 10000 +
            targetDateTime.month * 100 +
            targetDateTime.day;

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

    return activeServiceIds;
  }
}