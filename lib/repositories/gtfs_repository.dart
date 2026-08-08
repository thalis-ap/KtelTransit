import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:ktel_transit/models/calendar.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/models/route.dart';
import 'package:ktel_transit/models/stop_time.dart';

import 'package:csv/csv.dart';
import 'package:ktel_transit/utilities/time_format.dart';

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

  final ValueNotifier<Region> currentRegionNotifier = ValueNotifier(availableRegions.first);

  Region get currentRegion => currentRegionNotifier.value;

  Future<void> changeRegion(Region newRegion) async {
    // Update to new region, the re-load data
    currentRegionNotifier.value = newRegion;
    await loadData();
  }

  /// Asynchronously load route/trip/stop data from txt files
  Future<void> loadData() async {
    // Set to current region
    String regionId = currentRegion.id;

    // Clear old region data
    stops.clear();
    routes.clear();
    trips.clear();
    stopTimes.clear();
    calendars.clear();

    // Use the region id to find the specific txt files inside the correct dir
    String stopsString = await rootBundle.loadString("assets/gtfs/$regionId/stops.txt");

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

    String routesString = await rootBundle.loadString("assets/gtfs/$regionId/routes.txt");

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

    String tripsString = await rootBundle.loadString("assets/gtfs/$regionId/trips.txt");

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

  /// Find all departures from a stop if it's a starting one or
  /// arrivals to it if it's a terminal/middlepoint stop, after the
  /// selected time. This way we don't see departures of the past
  List<Departure> getDeparturesForStop(
    String departureStopId, {
    DateTime? selectedTime,
  }) {
    final DateTime target = selectedTime ?? DateTime.now();

    // Get the service ids for the selected date time (e.g. SATURDAY, WEEKDAY)
    List<String> validServiceIds = getServiceIds(target);

    int startMinutes = target.hour * 60 + target.minute;

    // Handle past-midnight trips
    if (target.hour < 4) {
      startMinutes += 24 * 60;
      final prevDay = target.subtract(const Duration(days: 1));

      validServiceIds = getServiceIds(prevDay);
    }

    // Find the departure stop object from the given id. At this point
    // we cannot get the StopTime object because it can be of another trip.
    // We must do so in the following for-loop, for the correct trip
    final Stop departureStop = stops.firstWhere(
      (s) => s.stopId == departureStopId,
    );

    // Find all the times at which a bus arrives on the target stop
    // after the selected time.
    List<StopTime> times = stopTimes.where((st) {
      if (st.stopId != departureStopId) return false;
      return TimeFormat.gtfsTimeToMinutes(st.arrivalTime) >= startMinutes;
    }).toList();

    times.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    // Now we are ready to find all corresponding departures
    final List<Departure> results = [];

    /// In this for loop we scan all StopTime objects. For each one of them
    /// we find to which trip it belongs. For example StopTimes are like
    /// 14:30 bus to Stop 1, Trip 123, 15:00 bus to Stop 1, Trip 124, ...
    /// Once we find the trip, we can then filter the StopTimes and get those
    /// that belong to the specific trip (Trip 123 for example).
    /// We then go on to find the start and destination of this trip, the route
    /// it's actually linked to and the corresponding times.
    for (StopTime st in times) {
      try {
        // Find the first suitable trip for every StopTime
        final Trip trip = trips.firstWhere((t) => t.tripId == st.tripId);

        // Skip trips that are on not supported days/dates
        if (!validServiceIds.contains(trip.serviceId)) continue;

        // Find the route that corresponds to this trip
        final Route route = routes.firstWhere((r) => r.routeId == trip.routeId);
        final String routeName = trip.getDisplayName(route.longName);

        // We now find all StopTime objects that correspond to a specific trip
        final List<StopTime> allTripsStopTimes = stopTimes
            .where((s) => s.tripId == trip.tripId)
            .toList();
        // Sort them by their stopSequence. This way we have all StopTimes
        // of a trip in their correct order.
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

    /// Sort by originDepartureTime. This way we see buses that leave first up
    /// on top. Note: We should not sort by departureTime. The attirbute
    /// departureTime inside a Departure object is the time a bus arrives
    /// or departs in the specific stop (Departure.departureStop). We should
    /// sort chronologically and let the user choose if a bus that arrives
    /// earlier is better than a bus that departs earlier
    results.sort(
      (a, b) => a.originDepartureTime.compareTo(b.originDepartureTime),
    );

    return results;
  }

  /// Returns a list of all trips found from the OSRM service back to the caller
  /// for the given DateTime (now if null)
  List<OsrmTrip> findAllTripsBetween(
    String startStopId,
    String destStopId, {
    DateTime? selectedTime,
  }) {
    final DateTime targetDateTime = selectedTime ?? DateTime.now();

    // Get the service ids for the selected date time (e.g. SATURDAY, WEEKDAY)
    List<String> validServiceIds = getServiceIds(targetDateTime);

    int startMinutes = targetDateTime.hour * 60 + targetDateTime.minute;
    if (targetDateTime.hour < 4) {
      startMinutes += 24 * 60;
      final prevDay = targetDateTime.subtract(const Duration(days: 1));

      validServiceIds = getServiceIds(prevDay);
    }

    // Find the stop times for the starting stop
    List<StopTime> startTimes = stopTimes.where((st) {
      if (st.stopId != startStopId) return false;
      return TimeFormat.gtfsTimeToMinutes(st.departureTime) >= startMinutes;
    }).toList();

    startTimes.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    List<OsrmTrip> dailyTrips = [];

    final String destinationStopName = stops
        .firstWhere((s) => s.stopId == destStopId)
        .name;

    // Find all direct trips first (if any)
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

        // Calculate total trip duration for sorting
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

    // If no direct trips exist then fallback to searching for trips with
    // bus change/transfer
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
              // Allow up to 24 hours of wait time between transfer trips
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

                // Calculate total trip duration for sorting
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
                    // origin and start are the same so we use the same date time
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

    // Sort all trips by their total time (fastest first)
    dailyTrips.sort((a, b) {
      // if (a. != b.estimatedDuration) {
      //   return a.estimatedDuration.compareTo(
      //     b.estimatedDuration,
      //   ); // Sort by duration ascending
      // }
      // If duration is identical, sort by departure time ascending
      return a.startDepartureDateTime.compareTo(b.startDepartureDateTime);
    });

    return dailyTrips;
  }

  /// Returns a list of active service_ids based on the given date time
  /// by checking the calendar table for valid date ranges and weekdays.
  List<String> getServiceIds(DateTime targetDateTime) {
    final List<String> activeServiceIds = [];

    // Format the target date to match the gtfs date format which is typically
    // yyyymmdd so that we can easily compare it as an integer against the
    // start and end dates provided in the calendar file
    final int targetDateInt =
        targetDateTime.year * 10000 +
        targetDateTime.month * 100 +
        targetDateTime.day;

    for (final calendar in calendars) {
      // We need to make sure the date we are looking for actually falls
      // within the active period of this specific calendar schedule because
      // gtfs feeds often include future or past schedules that shouldn't be
      // shown to the user right now
      try {
        final int startDate = int.parse(calendar.startDate);
        final int endDate = int.parse(calendar.endDate);

        if (targetDateInt < startDate || targetDateInt > endDate) {
          continue;
        }
      } catch (e) {
        continue;
      }

      // Figure out if this specific service runs on the day of the week
      // requested by the target date by matching dart's weekday integer
      // with the boolean flags parsed from the calendar file
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

  /// Returns a human readable string of the days a specific service operates
  /// by dynamically grouping consecutive active days into a clean format.
  String getReadableDays(String serviceId) {
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

      final List<String> dayNames = [
        'Δευτέρα',
        'Τρίτη',
        'Τετάρτη',
        'Πέμπτη',
        'Παρασκευή',
        'Σάββατο',
        'Κυριακή',
      ];

      // If every single day is marked as true we can immediately return
      // our daily keyword without needing to parse the individual blocks
      if (!activeFlags.contains(false)) {
        return "Καθημερινά";
      }

      List<String> formattedBlocks = [];
      int currentIndex = 0;

      // Loop through the entire week looking for active days so we can
      // group consecutive true values into human readable blocks
      while (currentIndex < 7) {
        if (activeFlags[currentIndex]) {
          int startIndex = currentIndex;

          // keep moving forward as long as the days are consecutive and active
          while (currentIndex < 7 && activeFlags[currentIndex]) {
            currentIndex++;
          }

          int endIndex = currentIndex - 1;

          // format the block based on how many consecutive days we found
          // so that it reads naturally in greek
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

      if (formattedBlocks.isEmpty) return "Άγνωστες Ημέρες";

      // join multiple distinct blocks with a comma in case the schedule
      // is split up like monday - wednesday, saturday - sunday
      return formattedBlocks.join(', ');
    } catch (e) {
      return "Άγνωστες Ημέρες";
    }
  }
}
