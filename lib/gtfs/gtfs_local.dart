import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:latlong2/latlong.dart';

import '../models/calendar.dart';
import '../models/stop.dart';
import '../models/route.dart';
import '../models/stop_time.dart';
import '../models/trip.dart';
import 'gtfs_repository.dart';

/// This file acts as the local gtfs files manager. It has nothing to do with
/// downloading, extracting files or accessing the github repo with the gtfs
/// data. It asserts files are in the local folder and simply loads them to
/// memory
class GtfsLocal {
  /// Loads all GTFS files from a directory path into the repository
  /// Returns true if successful, false otherwise
  Future<RegionLoadResult> loadFromPath(
      String regionPath,
      GtfsRepository repository, {
        required String languageCode,
      }) async {
    try {
      // Create temporary lists to hold data while loading.
      // This ensures we don't wipe the live repository if the load fails or takes time.
      final List<Stop> tempStops = [];
      final List<Route> tempRoutes = [];
      final List<Trip> tempTrips = [];
      final List<StopTime> tempStopTimes = [];
      final List<Calendar> tempCalendars = [];

      // Load translations (if exists)
      final translations = await _loadTranslations(regionPath, languageCode);

      // Load all files in parallel into our temporary lists
      List<RegionLoadResult> results = await Future.wait([
        _loadStops(regionPath, tempStops, translations),
        _loadRoutes(regionPath, tempRoutes, translations),
        _loadTrips(regionPath, tempTrips),
        _loadStopTimes(regionPath, tempStopTimes),
        _loadCalendar(regionPath, tempCalendars),
      ]);

      if (results.every((res) => res.isSuccess)) {
        // Atomic swap: Only clear and update the live repository once everything is ready
        repository.clear();
        repository.stops = tempStops;
        repository.routes = tempRoutes;
        repository.trips = tempTrips;
        repository.stopTimes = tempStopTimes;
        repository.calendars = tempCalendars;

        // Build indexes - this is required for performance
        repository.buildIndexes();

        return RegionLoadResult.success();
      } else {
        // Return the first error encountered
        return results.firstWhere((res) => !res.isSuccess);
      }
    } catch (e) {
      debugPrint('Error loading GTFS from $regionPath: $e');
      return RegionLoadResult.failure();
    }
  }

  // ---- Private loading methods ----
  Future<Map<String, String>> _loadTranslations(
      String regionPath,
      String languageCode,
      ) async {
    final filePath = '$regionPath/translations.txt';
    final file = File(filePath);
    if (!await file.exists()) return {};

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return {};

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    final tableNameIdx = headers['table_name'];
    final fieldNameIdx = headers['field_name'];
    final recordIdIdx = headers['record_id'];
    final languageIdx = headers['language'];
    final translationIdx = headers['translation'];

    if (tableNameIdx == null ||
        fieldNameIdx == null ||
        recordIdIdx == null ||
        languageIdx == null ||
        translationIdx == null) {
      return {};
    }

    final Map<String, String> translations = {};
    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.length < 2) continue;

      final lang = row[languageIdx].toString();
      if (lang != languageCode) continue;

      final tableName = row[tableNameIdx].toString();
      final fieldName = row[fieldNameIdx].toString();
      final recordId = row[recordIdIdx].toString();
      final translation = row[translationIdx].toString();

      if (tableName == 'stops' &&
          (fieldName == 'stop_name' || fieldName == 'stop_desc')) {
        translations['stop_$recordId'] = translation;
      } else if (tableName == 'routes') {
        if (fieldName == 'route_short_name') {
          translations['route_short_$recordId'] = translation;
        } else if (fieldName == 'route_long_name') {
          translations['route_long_$recordId'] = translation;
        }
      }
    }
    return translations;
  }

  Future<RegionLoadResult> _loadStops(
      String regionPath,
      List<Stop> outStops,
      Map<String, String> translations,
      ) async {
    final filePath = '$regionPath/stops.txt';
    final file = File(filePath);
    if (!await file.exists()) return RegionLoadResult.missingFiles();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.parsingFailed();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    final stopIdIdx = headers['stop_id'];
    final stopNameIdx = headers['stop_name'];
    final stopLatIdx = headers['stop_lat'];
    final stopLonIdx = headers['stop_lon'];

    if (stopIdIdx == null ||
        stopNameIdx == null ||
        stopLatIdx == null ||
        stopLonIdx == null) {
      debugPrint('stops.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.length < 4) continue;

      final stopId = row[stopIdIdx].toString();
      final name = row[stopNameIdx].toString();
      final lat = double.parse(row[stopLatIdx].toString());
      final lon = double.parse(row[stopLonIdx].toString());

      final translatedName = translations['stop_$stopId'] ?? name;

      outStops.add(
        Stop(
          stopId: stopId,
          name: translatedName,
          coordinates: LatLng(lat, lon),
        ),
      );
    }

    return RegionLoadResult.success();
  }

  Future<RegionLoadResult> _loadRoutes(
      String regionPath,
      List<Route> outRoutes,
      Map<String, String> translations,
      ) async {
    final filePath = '$regionPath/routes.txt';
    final file = File(filePath);
    if (!await file.exists()) return RegionLoadResult.missingFiles();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.parsingFailed();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    final agencyId = headers['agency_id'].toString();
    final routeIdIdx = headers['route_id'];
    final routeShortNameIdx = headers['route_short_name'];
    final routeLongNameIdx = headers['route_long_name'];
    final routeType = int.parse(headers['route_type'].toString());

    if (routeIdIdx == null ||
        routeShortNameIdx == null ||
        routeLongNameIdx == null) {
      debugPrint('routes.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.length < 3) continue;

      final routeId = row[routeIdIdx].toString();
      final shortName = row[routeShortNameIdx].toString();
      final longName = row[routeLongNameIdx].toString();

      final translatedShort = translations['route_short_$routeId'] ?? shortName;
      final translatedLong = translations['route_long_$routeId'] ?? longName;

      outRoutes.add(
        Route(
          agencyId: agencyId,
          routeId: routeId,
          shortName: translatedShort,
          longName: translatedLong,
          routeType: routeType,
        ),
      );
    }

    return RegionLoadResult.success();
  }

  Future<RegionLoadResult> _loadTrips(
      String regionPath,
      List<Trip> outTrips,
      ) async {
    final filePath = '$regionPath/trips.txt';
    final file = File(filePath);
    if (!await file.exists()) return RegionLoadResult.missingFiles();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.parsingFailed();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    final tripIdIdx = headers['trip_id'];
    final routeIdIdx = headers['route_id'];
    final serviceIdIdx = headers['service_id'];
    final headsignIdx = headers['trip_headsign'];
    final directionIdIdx = headers['direction_id'];

    if (tripIdIdx == null ||
        routeIdIdx == null ||
        serviceIdIdx == null ||
        headsignIdx == null ||
        directionIdIdx == null) {
      debugPrint('trips.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.length < 5) continue;

      final tripId = row[tripIdIdx].toString();
      final routeId = row[routeIdIdx].toString();
      final serviceId = row[serviceIdIdx].toString();
      final headsign = row[headsignIdx].toString();
      final directionId = int.parse(row[directionIdIdx].toString());

      outTrips.add(
        Trip(
          tripId: tripId,
          routeId: routeId,
          serviceId: serviceId,
          headsign: headsign,
          directionId: directionId,
        ),
      );
    }

    return RegionLoadResult.success();
  }

  Future<RegionLoadResult> _loadStopTimes(
      String regionPath,
      List<StopTime> outStopTimes,
      ) async {
    final filePath = '$regionPath/stop_times.txt';
    final file = File(filePath);
    if (!await file.exists()) return RegionLoadResult.missingFiles();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.parsingFailed();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    final tripIdIdx = headers['trip_id'];
    final stopIdIdx = headers['stop_id'];
    final arrivalTimeIdx = headers['arrival_time'];
    final departureTimeIdx = headers['departure_time'];
    final stopSequenceIdx = headers['stop_sequence'];

    if (tripIdIdx == null ||
        stopIdIdx == null ||
        arrivalTimeIdx == null ||
        departureTimeIdx == null ||
        stopSequenceIdx == null) {
      debugPrint('stop_times.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.length < 5) continue;

      final tripId = row[tripIdIdx].toString();
      final stopId = row[stopIdIdx].toString();
      final arrivalTime = row[arrivalTimeIdx].toString();
      final departureTime = row[departureTimeIdx].toString();
      final stopSequence = int.parse(row[stopSequenceIdx].toString());

      outStopTimes.add(
        StopTime(
          tripId: tripId,
          stopId: stopId,
          arrivalTime: arrivalTime,
          departureTime: departureTime,
          stopSequence: stopSequence,
        ),
      );
    }

    return RegionLoadResult.success();
  }

  Future<RegionLoadResult> _loadCalendar(
      String regionPath,
      List<Calendar> outCalendars,
      ) async {
    final filePath = '$regionPath/calendar.txt';
    final file = File(filePath);
    if (!await file.exists()) return RegionLoadResult.missingFiles();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.parsingFailed();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    final serviceIdIdx = headers['service_id'];
    final mondayIdx = headers['monday'];
    final tuesdayIdx = headers['tuesday'];
    final wednesdayIdx = headers['wednesday'];
    final thursdayIdx = headers['thursday'];
    final fridayIdx = headers['friday'];
    final saturdayIdx = headers['saturday'];
    final sundayIdx = headers['sunday'];
    final startDateIdx = headers['start_date'];
    final endDateIdx = headers['end_date'];

    if (serviceIdIdx == null ||
        mondayIdx == null ||
        tuesdayIdx == null ||
        wednesdayIdx == null ||
        thursdayIdx == null ||
        fridayIdx == null ||
        saturdayIdx == null ||
        sundayIdx == null ||
        startDateIdx == null ||
        endDateIdx == null) {
      debugPrint('calendar.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.length < 10) continue;

      final serviceId = row[serviceIdIdx].toString();
      final monday = row[mondayIdx].toString() == '1';
      final tuesday = row[tuesdayIdx].toString() == '1';
      final wednesday = row[wednesdayIdx].toString() == '1';
      final thursday = row[thursdayIdx].toString() == '1';
      final friday = row[fridayIdx].toString() == '1';
      final saturday = row[saturdayIdx].toString() == '1';
      final sunday = row[sundayIdx].toString() == '1';
      final startDate = row[startDateIdx].toString();
      final endDate = row[endDateIdx].toString();

      outCalendars.add(
        Calendar(
          serviceId: serviceId,
          monday: monday,
          tuesday: tuesday,
          wednesday: wednesday,
          thursday: thursday,
          friday: friday,
          saturday: saturday,
          sunday: sunday,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    }

    return RegionLoadResult.success();
  }
}