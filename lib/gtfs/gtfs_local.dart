import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:ktel_transit/models/agency.dart';
import 'package:ktel_transit/utilities/region_utils.dart';

import '../models/calendar.dart';
import '../models/calendar_date.dart';
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
      final List<Agency> tempAgencies = [];
      final List<Stop> tempStops = [];
      final List<Route> tempRoutes = [];
      final List<Trip> tempTrips = [];
      final List<StopTime> tempStopTimes = [];
      final List<Calendar> tempCalendars = [];
      final List<CalendarDate> tempCalendarDates = [];

      // Load translations (if exists)
      final translations = await _loadTranslations(regionPath, languageCode);

      // Load all files in parallel into our temporary lists
      List<RegionLoadResult> results = await Future.wait([
        _loadAgencies(regionPath, tempAgencies, translations),
        _loadStops(regionPath, tempStops, translations),
        _loadRoutes(regionPath, tempRoutes, translations),
        _loadTrips(regionPath, tempTrips),
        _loadStopTimes(regionPath, tempStopTimes),
        _loadCalendar(regionPath, tempCalendars),
        _loadCalendarDates(regionPath, tempCalendarDates),
      ]);

      if (results.every((res) => res.isSuccess)) {
        // Atomic swap: Only clear and update the live repository once everything is ready
        repository.clear();
        repository.agencies = tempAgencies;
        repository.stops = tempStops;
        repository.routes = tempRoutes;
        repository.trips = tempTrips;
        repository.stopTimes = tempStopTimes;
        repository.calendars = tempCalendars;
        repository.calendarDates = tempCalendarDates;

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
        translations['${fieldName}_$recordId'] = translation;
      } else if (tableName == 'routes') {
        if (fieldName == 'route_short_name') {
          translations['route_short_$recordId'] = translation;
        } else if (fieldName == 'route_long_name') {
          translations['route_long_$recordId'] = translation;
        }
      } else {
        translations[recordId] = translation;
      }
    }
    return translations;
  }

  Future<RegionLoadResult> _loadAgencies(
    String regionPath,
    List<Agency> outAgencies,
    Map<String, String> translations,
  ) async {
    final filePath = '$regionPath/agency.txt';
    final file = File(filePath);
    if (!await file.exists()) return RegionLoadResult.missingFiles();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.parsingFailed();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    if (!Agency.hasRequiredHeaders(headers)) {
      debugPrint('agency.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!Agency.isValidRow(row, headers)) continue;

      final agencyId = row[headers[Agency.agencyIdKey]!].toString().trim();
      final translatedName = translations[agencyId];

      outAgencies.add(Agency.fromCsv(row, headers, translatedName: translatedName));
    }

    return RegionLoadResult.success();
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

    if (!Stop.hasRequiredHeaders(headers)) {
      debugPrint('stops.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!Stop.isValidRow(row, headers)) continue;

      final stopId = row[headers['stop_id']!].toString().trim();
      final translatedName = translations['stop_name_$stopId'];
      final translatedDesc = translations['stop_desc_$stopId'];

      outStops.add(Stop.fromCsv(
        row,
        headers,
        translatedName: translatedName,
        translatedDesc: translatedDesc,
      ));
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

    if (!Route.hasRequiredHeaders(headers)) {
      debugPrint('routes.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!Route.isValidRow(row, headers)) continue;

      final routeId = row[headers['route_id']!].toString().trim();
      final translatedShort = translations['route_short_$routeId'];
      final translatedLong = translations['route_long_$routeId'];

      outRoutes.add(Route.fromCsv(
        row,
        headers,
        translatedShortName: translatedShort,
        translatedLongName: translatedLong,
      ));
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

    if (!Trip.hasRequiredHeaders(headers)) {
      debugPrint('trips.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!Trip.isValidRow(row, headers)) continue;
      outTrips.add(Trip.fromCsv(row, headers));
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

    if (!StopTime.hasRequiredHeaders(headers)) {
      debugPrint('stop_times.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!StopTime.isValidRow(row, headers)) continue;
      outStopTimes.add(StopTime.fromCsv(row, headers));
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

    if (!Calendar.hasRequiredHeaders(headers)) {
      debugPrint('calendar.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!Calendar.isValidRow(row, headers)) continue;
      outCalendars.add(Calendar.fromCsv(row, headers));
    }

    return RegionLoadResult.success();
  }

  Future<RegionLoadResult> _loadCalendarDates(
    String regionPath,
    List<CalendarDate> outCalendarDates,
  ) async {
    final filePath = '$regionPath/calendar_dates.txt';
    final file = File(filePath);

    // This file is optional according to GTFS specs.
    // If it doesn't exist, we just return success and leave the list empty.
    if (!await file.exists()) return RegionLoadResult.success();

    final content = await file.readAsString();
    final rows = csv.decode(content);
    if (rows.isEmpty) return RegionLoadResult.success();

    final headers = {
      for (int i = 0; i < rows[0].length; i++) rows[0][i].toString(): i,
    };

    if (!CalendarDate.hasRequiredHeaders(headers)) {
      debugPrint('calendar_dates.txt missing required columns');
      return RegionLoadResult.parsingFailed();
    }

    for (final row in rows.skip(1)) {
      if (!CalendarDate.isValidRow(row, headers)) continue;
      outCalendarDates.add(CalendarDate.fromCsv(row, headers));
    }

    return RegionLoadResult.success();
  }
}
