import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ktel_transit/models/calendar.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/models/route.dart';
import 'package:ktel_transit/models/stop_time.dart';

import 'package:csv/csv.dart';
import 'package:ktel_transit/utilities/time_format.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/region.dart';

/// This class handles the gtfs data from the txt files
class GtfsRepository {
  List<Stop> stops = [];
  List<Route> routes = [];
  List<Trip> trips = [];
  List<StopTime> stopTimes = [];
  List<Calendar> calendars = [];

  static final GtfsRepository _instance = GtfsRepository._internal();
  factory GtfsRepository() => _instance;
  GtfsRepository._internal();

  final ValueNotifier<Region?> currentRegionNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isRegionLoadingNotifier = ValueNotifier(false);

  Region? get currentRegion => currentRegionNotifier.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRegionId = prefs.getString('saved_region_id');

    if (savedRegionId != null) {
      final savedRegion = availableRegions.firstWhere(
            (region) => region.id == savedRegionId,
        orElse: () => availableRegions.first,
      );
      currentRegionNotifier.value = savedRegion;
    }

    await loadData();
  }

  Future<void> changeRegion(Region newRegion) async {
    final bool didActuallyChange =
        currentRegionNotifier.value?.id != newRegion.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_region_id', newRegion.id);

    if (didActuallyChange) {
      isRegionLoadingNotifier.value = true;
      // Maybe remove this in the future, but it's very faster than 1 second
      await Future.delayed(Duration(seconds: 1));
      await loadData(newRegion);
      isRegionLoadingNotifier.value = false;
    }

    currentRegionNotifier.value = newRegion;
  }

  Future<void> loadData([Region? region]) async {
    final regionToLoad = region ?? currentRegion;

    if (regionToLoad == null) return;

    String regionId = regionToLoad.id;

    stops.clear();
    routes.clear();
    trips.clear();
    stopTimes.clear();
    calendars.clear();

    String stopsString =
    await rootBundle.loadString("assets/gtfs/$regionId/stops.txt");
    List<List<dynamic>> stopsGrid = csv.decode(stopsString);

    if (stopsGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < stopsGrid[0].length; i++)
          stopsGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in stopsGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;
        stops.add(Stop.fromCsv(row, headers));
      }
    }

    String routesString =
    await rootBundle.loadString("assets/gtfs/$regionId/routes.txt");
    List<List<dynamic>> routesGrid = csv.decode(routesString);

    if (routesGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < routesGrid[0].length; i++)
          routesGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in routesGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;
        routes.add(Route.fromCsv(row, headers));
      }
    }

    String tripsString =
    await rootBundle.loadString("assets/gtfs/$regionId/trips.txt");
    List<List<dynamic>> tripsGrid = csv.decode(tripsString);

    if (tripsGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < tripsGrid[0].length; i++)
          tripsGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in tripsGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;
        trips.add(Trip.fromCsv(row, headers));
      }
    }

    String stopTimesString = await rootBundle.loadString(
      "assets/gtfs/$regionId/stop_times.txt",
    );
    List<List<dynamic>> stopTimesGrid = csv.decode(stopTimesString);

    if (stopTimesGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < stopTimesGrid[0].length; i++)
          stopTimesGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in stopTimesGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;
        stopTimes.add(StopTime.fromCsv(row, headers));
      }
    }

    String calendarString = await rootBundle.loadString(
      "assets/gtfs/$regionId/calendar.txt",
    );
    List<List<dynamic>> calendarGrid = csv.decode(calendarString);

    if (calendarGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < calendarGrid[0].length; i++)
          calendarGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in calendarGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;
        calendars.add(Calendar.fromCsv(row, headers));
      }
    }
  }

  List<Departure> getDeparturesForStop(
      String departureStopId, {
        DateTime? selectedTime,
      }) {
    final DateTime target = selectedTime ?? DateTime.now();

    List<String> validServiceIds = getServiceIds(target);
    int startMinutes = target.hour * 60 + target.minute;

    if (target.hour < 4) {
      startMinutes += 24 * 60;
      final prevDay = target.subtract(const Duration(days: 1));
      validServiceIds = getServiceIds(prevDay);
    }

    final Stop departureStop = stops.firstWhere(
          (s) => s.stopId == departureStopId,
    );

    List<StopTime> times = stopTimes.where((st) {
      if (st.stopId != departureStopId) return false;
      return TimeFormat.gtfsTimeToMinutes(st.arrivalTime) >= startMinutes;
    }).toList();

    times.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    final List<Departure> results = [];

    for (StopTime st in times) {
      try {
        final Trip trip = trips.firstWhere((t) => t.tripId == st.tripId);
        if (!validServiceIds.contains(trip.serviceId)) continue;

        final Route route = routes.firstWhere((r) => r.routeId == trip.routeId);
        final String routeName = trip.getDisplayName(route.longName);

        final List<StopTime> allTripsStopTimes = stopTimes
            .where((s) => s.tripId == trip.tripId)
            .toList();
        allTripsStopTimes.sort(
              (a, b) => a.stopSequence.compareTo(b.stopSequence),
        );

        final StopTime originStopTime = allTripsStopTimes.first;
        final StopTime destinationStopTime = allTripsStopTimes.last;
        final StopTime departureStopTime = allTripsStopTimes.firstWhere(
              (s) => s.stopId == departureStopId,
        );

        final Stop originStop = stops.firstWhere(
              (s) => s.stopId == originStopTime.stopId,
        );
        final Stop destinationStop = stops.firstWhere(
              (s) => s.stopId == destinationStopTime.stopId,
        );

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

  List<OsrmTrip> findAllTripsBetween(
      String startStopId,
      String destStopId, {
        DateTime? selectedTime,
      }) {
    final DateTime targetDateTime = selectedTime ?? DateTime.now();

    List<String> validServiceIds = getServiceIds(targetDateTime);

    int startMinutes = targetDateTime.hour * 60 + targetDateTime.minute;
    if (targetDateTime.hour < 4) {
      startMinutes += 24 * 60;
      final prevDay = targetDateTime.subtract(const Duration(days: 1));
      validServiceIds = getServiceIds(prevDay);
    }

    List<StopTime> startTimes = stopTimes.where((st) {
      if (st.stopId != startStopId) return false;
      return TimeFormat.gtfsTimeToMinutes(st.departureTime) >= startMinutes;
    }).toList();

    startTimes.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    List<OsrmTrip> dailyTrips = [];

    final String destinationStopName = stops
        .firstWhere((s) => s.stopId == destStopId)
        .name;

    for (StopTime stStart in startTimes) {
      try {
        final Trip trip = trips.firstWhere((t) => t.tripId == stStart.tripId);
        if (!validServiceIds.contains(trip.serviceId)) continue;

        final List<StopTime> destTimes = stopTimes
            .where((st) => st.tripId == trip.tripId && st.stopId == destStopId)
            .toList();
        if (destTimes.isEmpty) continue;

        final StopTime stDest = destTimes.first;
        if (stDest.stopSequence <= stStart.stopSequence) continue;

        final int durationMins =
            TimeFormat.gtfsTimeToMinutes(stDest.arrivalTime) -
                TimeFormat.gtfsTimeToMinutes(stStart.departureTime);

        final Route route = routes.firstWhere((r) => r.routeId == trip.routeId);
        String displayName = trip.getDisplayName(route.longName);

        final List<StopTime> allTripStops = stopTimes
            .where((s) => s.tripId == trip.tripId)
            .toList();
        allTripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
        final StopTime firstStop = allTripStops.first;

        final String originStopName = stops
            .firstWhere((s) => s.stopId == firstStop.stopId)
            .name;

        dailyTrips.add(
          OsrmTrip(
            isStartAlsoOrigin: firstStop.stopId == startStopId,
            routeName: displayName,
            originStopName: originStopName,
            destinationStopName: destinationStopName,
            originDepartureDateTime: TimeFormat.gtfsTimeToDateTime(
              targetDateTime,
              firstStop.departureTime,
            ),
            startDepartureDateTime: TimeFormat.gtfsTimeToDateTime(
              targetDateTime,
              stStart.departureTime,
            ),
            destArrivalDateTime: TimeFormat.gtfsTimeToDateTime(
              targetDateTime,
              stDest.arrivalTime,
            ),
            isTransfer: false,
            estimatedDuration: durationMins,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    if (dailyTrips.isEmpty) {
      for (StopTime stStart in startTimes) {
        try {
          final Trip tripA = trips.firstWhere(
                (t) => t.tripId == stStart.tripId,
          );
          if (!validServiceIds.contains(tripA.serviceId)) continue;

          final List<StopTime> tripAStops = stopTimes
              .where(
                (st) =>
            st.tripId == tripA.tripId &&
                st.stopSequence > stStart.stopSequence,
          )
              .toList();

          tripAStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
          final StopTime firstStop = tripAStops.first;

          final String originStopName = stops.firstWhere(
                (s) => s.stopId == firstStop.stopId,
          ).name;

          for (StopTime transferA in tripAStops) {
            final int tArrivalMins = TimeFormat.gtfsTimeToMinutes(
              transferA.arrivalTime,
            );

            List<StopTime> potentialLeg2 = stopTimes.where((st) {
              if (st.stopId != transferA.stopId) return false;
              final tDepartMins = TimeFormat.gtfsTimeToMinutes(
                st.departureTime,
              );
              return tDepartMins >= tArrivalMins &&
                  tDepartMins <= tArrivalMins + 1440;
            }).toList();

            for (StopTime stTransB in potentialLeg2) {
              final Trip tripB = trips.firstWhere(
                    (t) => t.tripId == stTransB.tripId,
              );
              if (!validServiceIds.contains(tripB.serviceId)) continue;
              if (tripA.tripId == tripB.tripId) continue;

              final List<StopTime> destTimes = stopTimes
                  .where(
                    (st) =>
                st.tripId == tripB.tripId &&
                    st.stopId == destStopId &&
                    st.stopSequence > stTransB.stopSequence,
              )
                  .toList();

              if (destTimes.isNotEmpty) {
                final StopTime stDest = destTimes.first;

                final int durationMins =
                    TimeFormat.gtfsTimeToMinutes(stDest.arrivalTime) -
                        TimeFormat.gtfsTimeToMinutes(stStart.departureTime);

                final Route routeA = routes.firstWhere(
                      (r) => r.routeId == tripA.routeId,
                );
                final Route routeB = routes.firstWhere(
                      (r) => r.routeId == tripB.routeId,
                );
                final String transferStopName = stops
                    .firstWhere((s) => s.stopId == transferA.stopId)
                    .name;

                String rAName = routeA.longName;
                if (tripA.directionId.toString() == '1') {
                  rAName = rAName.split(' - ').reversed.join(' - ');
                }
                String rBName = routeB.longName;
                if (tripB.directionId.toString() == '1') {
                  rBName = rBName.split(' - ').reversed.join(' - ');
                }

                dailyTrips.add(
                  OsrmTrip(
                    isStartAlsoOrigin: true,
                    routeName: '1. $rAName\n2. $rBName',
                    originStopName: originStopName,
                    destinationStopName: destinationStopName,
                    originDepartureDateTime: TimeFormat.gtfsTimeToDateTime(
                      targetDateTime,
                      stStart.departureTime,
                    ),
                    startDepartureDateTime: TimeFormat.gtfsTimeToDateTime(
                      targetDateTime,
                      stStart.departureTime,
                    ),
                    destArrivalDateTime: TimeFormat.gtfsTimeToDateTime(
                      targetDateTime,
                      stDest.arrivalTime,
                    ),
                    isTransfer: true,
                    estimatedDuration: durationMins,
                    transferStopName: transferStopName,
                    transferArrivalDateTime: TimeFormat.gtfsTimeToDateTime(
                      targetDateTime,
                      transferA.arrivalTime,
                    ),
                    transferDepartureDateTime: TimeFormat.gtfsTimeToDateTime(
                      targetDateTime,
                      stTransB.departureTime,
                    ),
                  ),
                );
              }
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

  List<String> getServiceIds(DateTime targetDateTime) {
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

  /// Returns a human readable string of the operating days localized to the user's active language.
  String getReadableDays(String serviceId, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final calendar = calendars.firstWhere((c) => c.serviceId == serviceId);

      final List<bool> activeFlags = [
        calendar.monday,
        calendar.tuesday,
        calendar.wednesday,
        calendar.thursday,
        calendar.friday,
        calendar.saturday,
        calendar.sunday,
      ];

      // Base Monday reference date (2024-01-01 was a Monday)
      final baseMonday = DateTime(2024, 1, 1);
      final List<String> dayNames = List.generate(7, (i) {
        final dayDate = baseMonday.add(Duration(days: i));
        final name = DateFormat('EEEE', locale).format(dayDate);
        return name[0].toUpperCase() + name.substring(1);
      });

      if (!activeFlags.contains(false)) {
        return l10n.daily;
      }

      List<String> formattedBlocks = [];
      int currentIndex = 0;

      while (currentIndex < 7) {
        if (activeFlags[currentIndex]) {
          int startIndex = currentIndex;

          while (currentIndex < 7 && activeFlags[currentIndex]) {
            currentIndex++;
          }

          int endIndex = currentIndex - 1;

          if (startIndex == endIndex) {
            formattedBlocks.add(dayNames[startIndex]);
          } else if (endIndex == startIndex + 1) {
            formattedBlocks.add(
              "${dayNames[startIndex]} & ${dayNames[endIndex]}",
            );
          } else {
            formattedBlocks.add(
              "${dayNames[startIndex]} - ${dayNames[endIndex]}",
            );
          }
        } else {
          currentIndex++;
        }
      }

      if (formattedBlocks.isEmpty) return l10n.unknownDays;

      return formattedBlocks.join(', ');
    } catch (e) {
      return l10n.unknownDays;
    }
  }
}