import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ktel_transit/models/calendar.dart';
import 'package:ktel_transit/models/departure.dart';
import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/stop.dart';
import 'package:ktel_transit/models/trip.dart';
import 'package:ktel_transit/models/route.dart';
import 'package:ktel_transit/models/stop_time.dart';

import 'package:csv/csv.dart';
import 'package:ktel_transit/services/settings_service.dart';
import 'package:ktel_transit/utilities/notifiers.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
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

  // Fast-lookup indexes, rebuilt whenever data loads
  Map<String, List<StopTime>> _stopTimesByStopId = {};
  Map<String, List<StopTime>> _stopTimesByTripId = {};
  Map<String, Trip> _tripsById = {};
  Map<String, Route> _routesById = {};
  Map<String, Stop> _stopsById = {};

  SettingsController? _settingsController;

  static final GtfsRepository _instance = GtfsRepository._internal();

  factory GtfsRepository() => _instance;

  GtfsRepository._internal();

  // This notifier handles the region change
  final CustomValueNotifier<Region?> currentRegionNotifier =
      CustomValueNotifier(null);

  // This is an extra notifier to let any widgets know when the region is loaded
  final ValueNotifier<bool> isRegionLoadingNotifier = ValueNotifier(false);

  Region? get currentRegion => currentRegionNotifier.value;

  String dataPath(String regionId, String fileName) =>
      "assets/gtfs/$regionId/$fileName";

  Future<void> init({SettingsController? settingsController}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedRegionId = prefs.getString(RegionUtils.savedRegionIdKey);

    if (savedRegionId != null) {
      final savedRegion = availableRegions.firstWhere(
        (region) => region.id == savedRegionId,
        orElse: () => availableRegions.first,
      );
      currentRegionNotifier.value = savedRegion;
    }

    if (settingsController != null) {
      _settingsController = settingsController;
    }

    await loadData();
  }

  Future<void> changeRegion(Region newRegion) async {
    // Check if the region changed
    if (currentRegionNotifier.value?.id != newRegion.id) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(RegionUtils.savedRegionIdKey, newRegion.id);

      isRegionLoadingNotifier.value = true;
      // Maybe remove this in the future - extra delay
      await Future.delayed(Duration(milliseconds: 500));
      await loadData(newRegion);
      isRegionLoadingNotifier.value = false;

      currentRegionNotifier.value = newRegion;
    } else {
      // Notify listeners anyway, region is the same but we must animate the map
      currentRegionNotifier.forceNotify();
    }
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

    // Load translations into a Map
    Map<String, String> stopTranslations = {};
    Map<String, String> routeShortNameTranslations = {};
    Map<String, String> routeLongNameTranslations = {};

    try {
      String translationsString = await rootBundle.loadString(
        dataPath(regionId, "translations.txt"),
      );
      List<List<dynamic>> translationsGrid = csv.decode(translationsString);

      if (translationsGrid.isNotEmpty) {
        final headers = {
          for (int i = 0; i < translationsGrid[0].length; i++)
            translationsGrid[0][i].toString(): i,
        };

        for (List<dynamic> row in translationsGrid.skip(1)) {
          if (row.isEmpty || row.length < 2) continue;

          final tableNameIdx = headers['table_name'];
          final fieldNameIdx = headers['field_name'];
          final languageIdx = headers['language'];
          final translationIdx = headers['translation'];
          final recordIdIdx = headers['record_id'];

          if (languageIdx == null ||
              translationIdx == null ||
              recordIdIdx == null) {
            continue;
          }

          final language = row[languageIdx].toString();
          if (language != 'en') continue;

          final tableName = tableNameIdx != null
              ? row[tableNameIdx].toString()
              : 'stops';
          final fieldName = fieldNameIdx != null
              ? row[fieldNameIdx].toString()
              : 'stop_name';
          final recordId = row[recordIdIdx].toString();
          final translation = row[translationIdx].toString();

          if (tableName == 'stops' &&
              (fieldName == 'stop_name' || fieldName == 'stop_desc')) {
            stopTranslations[recordId] = translation;
          } else if (tableName == 'routes') {
            if (fieldName == 'route_short_name') {
              routeShortNameTranslations[recordId] = translation;
            } else if (fieldName == 'route_long_name') {
              routeLongNameTranslations[recordId] = translation;
            }
          }
        }
      }
    } catch (_) {
      // Missing translations.txt is fine, it will just leave the Map empty
    }

    String stopsString = await rootBundle.loadString(
      dataPath(regionId, "stops.txt"),
    );
    List<List<dynamic>> stopsGrid = csv.decode(stopsString);

    if (stopsGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < stopsGrid[0].length; i++)
          stopsGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in stopsGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;

        // Grab the ID first so we can check our dictionary
        final stopId = row[headers['stop_id']!].toString();

        stops.add(
          Stop.fromCsv(row, headers, englishName: stopTranslations[stopId]),
        );
      }
    }

    String routesString = await rootBundle.loadString(
      dataPath(regionId, "routes.txt"),
    );
    List<List<dynamic>> routesGrid = csv.decode(routesString);

    if (routesGrid.isNotEmpty) {
      final headers = {
        for (int i = 0; i < routesGrid[0].length; i++)
          routesGrid[0][i].toString(): i,
      };

      for (List<dynamic> row in routesGrid.skip(1)) {
        if (row.isEmpty || row.length < 2) continue;

        final routeId = row[headers['route_id']!].toString();

        routes.add(
          Route.fromCsv(
            row,
            headers,
            englishShortName: routeShortNameTranslations[routeId],
            englishLongName: routeLongNameTranslations[routeId],
          ),
        );
      }
    }

    String tripsString = await rootBundle.loadString(
      dataPath(regionId, "trips.txt"),
    );
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
      dataPath(regionId, "stop_times.txt"),
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
      dataPath(regionId, "calendar.txt"),
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

    _buildIndexes();
  }

  /// Helper function to build up the indexes that will help resolve calls to
  /// the stops, trips, routes fields faster
  void _buildIndexes() {
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

  /// Returns the ordered list of stop names for a trip ID.
  List<String> _getStopNamesForTrip(String tripId, String languageCode) {
    final stopTimes = _stopTimesByTripId[tripId] ?? [];
    if (stopTimes.isEmpty) return [];

    final sorted = List<StopTime>.from(stopTimes)
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    return sorted.map((st) {
      final stop = _stopsById[st.stopId];
      return stop?.getLocalizedNameByLangCode(languageCode) ?? st.stopId;
    }).toList();
  }

  List<Departure> getDeparturesForStop(
    String departureStopId, {
    DateTime? selectedTime,
  }) {
    final languageCode = _settingsController?.locale.languageCode ?? 'el';
    final DateTime target = selectedTime ?? DateTime.now();

    List<String> validServiceIds = getServiceIds(target);
    int startMinutes = target.hour * 60 + target.minute;

    if (target.hour < 4) {
      startMinutes += 24 * 60;
      final prevDay = target.subtract(const Duration(days: 1));
      validServiceIds = getServiceIds(prevDay);
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
          route.getLocalizedLongName(languageCode),
        );

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

  /// Searches for trips between two stops on a specific date.
  /// Returns an empty list if no trips are found.
  List<BusTrip> _findTripsForDate(
    String startStopId,
    String destStopId,
    DateTime date,
  ) {
    final languageCode = _settingsController?.locale.languageCode ?? 'el';
    final maxWaitMinutes = _settingsController?.maxWaitTime ?? 24;

    // Get service IDs valid on this date
    List<String> validServiceIds = getServiceIds(date);

    // Get start minutes, handling early-morning (before 4 AM) as previous day
    int startMinutes = date.hour * 60 + date.minute;
    DateTime effectiveDate = date;
    if (date.hour < 4) {
      startMinutes += 24 * 60;
      effectiveDate = date.subtract(const Duration(days: 1));
      validServiceIds = getServiceIds(effectiveDate);
    }

    // Find all departures from start stop after the given minute
    List<StopTime> startTimes = (_stopTimesByStopId[startStopId] ?? [])
        .where(
          (st) =>
              TimeFormat.gtfsTimeToMinutes(st.departureTime) >= startMinutes,
        )
        .toList();
    startTimes.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    final String destinationStopName =
        (_stopsById[destStopId])?.getLocalizedNameByLangCode(languageCode) ?? '';
    final String originStopName =
        (_stopsById[startStopId])?.getLocalizedNameByLangCode(languageCode) ?? '';

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

        String displayName = trip.getDisplayName(
          route.getLocalizedLongName(languageCode),
        );

        final List<StopTime> allTripStops = List.of(
          _stopTimesByTripId[trip.tripId] ?? [],
        );
        allTripStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

        final stopNames = _getStopNamesForTrip(trip.tripId, languageCode);

        final leg = BusLeg(
          routeName: displayName,
          originStopName: originStopName,
          destinationStopName: destinationStopName,
          departureDateTime: TimeFormat.gtfsTimeToDateTime(date, stStart.departureTime),
          arrivalDateTime: TimeFormat.gtfsTimeToDateTime(date, stDest.arrivalTime),
          estimatedDuration: durationSecs,
          stopNames: stopNames,
          originStop: _stopsById[startStopId]!,
          destinationStop: _stopsById[destStopId]!,
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
                      tDepartMins <= tArrivalMins + 60 * maxWaitMinutes;
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

              final String transferStopName =
                  _stopsById[transferA.stopId]?.getLocalizedNameByLangCode(
                    languageCode,
                  ) ??
                  '';

              String rAName = tripA.getDisplayName(
                routeA.getLocalizedLongName(languageCode),
              );
              String rBName = tripB.getDisplayName(
                routeB.getLocalizedLongName(languageCode),
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
              final stopNamesA = _getStopNamesForTrip(tripA.tripId, languageCode);
              final stopNamesB = _getStopNamesForTrip(tripB.tripId, languageCode);

              final leg1 = BusLeg(
                routeName: rAName,
                originStopName: originStopName,
                destinationStopName: transferStopName,
                departureDateTime: TimeFormat.gtfsTimeToDateTime(date, stStart.departureTime),
                arrivalDateTime: TimeFormat.gtfsTimeToDateTime(date, transferA.arrivalTime),
                estimatedDuration: durationLeg1,
                stopNames: stopNamesA,
                originStop: _stopsById[startStopId]!,
                destinationStop: _stopsById[transferA.stopId]!,
              );

              final leg2 = BusLeg(
                routeName: rBName,
                originStopName: transferStopName,
                destinationStopName: destinationStopName,
                departureDateTime: TimeFormat.gtfsTimeToDateTime(date, stTransB.departureTime),
                arrivalDateTime: TimeFormat.gtfsTimeToDateTime(date, stDest.arrivalTime),
                estimatedDuration: durationLeg2,
                stopNames: stopNamesB,
                originStop: _stopsById[transferA.stopId]!,
                destinationStop: _stopsById[destStopId]!,
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
