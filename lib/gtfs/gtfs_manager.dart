import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:ktel_transit/gtfs/gtfs_local.dart';
import 'package:ktel_transit/gtfs/gtfs_remote.dart';
import 'package:ktel_transit/gtfs/gtfs_repository.dart';
import 'package:ktel_transit/gtfs/gtfs_storage.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/services/settings_service.dart';
import 'package:ktel_transit/utilities/notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utilities/region_utils.dart';

/// This file acts as a general Gtfs orchestrator. It is responsible for choosing
/// whether we need to download files from the remote repo, or we already have
/// them downloaded. In case of download, it calls GtfsRemote() and when it
/// successfully finishes the download, it passes the lever to GtfsLocal() to
/// continue with loading the files in memory.
class GtfsManager {
  static final GtfsManager _instance = GtfsManager._internal();

  factory GtfsManager() => _instance;

  GtfsManager._internal();

  bool _isInitialized = false;

  SettingsController? _settingsController;

  GtfsStorage _storage = GtfsStorage();

  GtfsLocal _local = GtfsLocal();
  GtfsRemote _remote = GtfsRemote();

  GtfsRepository _repository = GtfsRepository();

  // ---- State Notifiers ----
  final CustomValueNotifier<Region?> currentRegionNotifier =
      CustomValueNotifier(null);

  final CustomValueNotifier<RegionState> stateNotifier =
      CustomValueNotifier<RegionState>(RegionState.idle);

  final CustomValueNotifier<double> progressNotifier =
      CustomValueNotifier<double>(0.0);

  // ---- Per-Region Status Cache ----
  final Map<String, RegionStatus> _regionStatusCache = {};

  RegionLoadResult? _lastLoadResult;

  // Getter for quick access
  Region? get currentRegion => currentRegionNotifier.value;

  GtfsRepository get repository => _repository;

  RegionLoadResult? get lastLoadResult => _lastLoadResult;

  Future<void> init({required SettingsController settingsController}) async {
    if (_isInitialized) return;

    _settingsController = settingsController;

    // Loads each region's status in memory
    await loadRegionStatuses();

    // Get the last saved region
    final String? savedRegionId = await RegionUtils.getSavedRegion();

    if (savedRegionId != null) {
      setCurrentRegion(savedRegionId);
    }

    _isInitialized = true;
  }

  // Region status

  /// Populates _regionStatusCache so that we have each region status in
  /// memory for fast lookup.
  Future<void> loadRegionStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final statusesJson = prefs.getString('region_statuses');
    if (statusesJson == null) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(statusesJson);
      for (final entry in decoded.entries) {
        final regionId = entry.key;
        final statusMap = entry.value as Map<String, dynamic>;
        _regionStatusCache[regionId] = RegionStatus.fromJson(statusMap);
      }
    } catch (e) {
      debugPrint('Error loading region statuses: $e');
    }
  }

  /// Saves the new region status (for regionId) to both cache and SharedPrefs
  Future<void> _saveRegionStatus(String regionId, RegionStatus status) async {
    // Update cache
    _regionStatusCache[regionId] = status;

    // Save all to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> allStatuses = {};
    for (final entry in _regionStatusCache.entries) {
      allStatuses[entry.key] = entry.value.toJson();
    }
    await prefs.setString('region_statuses', jsonEncode(allStatuses));
  }

  /// Helper function to get a region's status by its id
  RegionStatus getRegionStatus(String regionId) {
    return _regionStatusCache[regionId] ?? const RegionStatus();
  }

  /// Loads the requested region (by id) into the currentRegion variable
  /// After this function completes a user shall be able to access ALL
  /// information regarding the loaded region. In case anything goes wrong
  /// it will return false, and the caller is responsible to check status
  /// trought stateNotifier
  Future<RegionLoadResult> loadRegion(String regionId) async {
    // Ensure we have a settings controller (should be initialized)
    if (_settingsController == null) {
      stateNotifier.value = RegionState.error;
      return RegionLoadResult.failure(errorCode: RegionErrorCode.unknown);
    }

    final languageCode = _settingsController!.locale.languageCode;

    // Prematurely set the current region so it's available for callers
    setCurrentRegion(regionId);

    // Get the last saved region status
    RegionStatus regionStatus = getRegionStatus(regionId);

    // Local variable to hold the result
    RegionLoadResult result;

    try {
      // If region is already ready, load from local storage
      if (regionStatus.isReady) {
        print("Its ready!");
        stateNotifier.value = RegionState.loading;

        // Add small added delay to not clamp widgets together
        await Future.delayed(Duration(seconds: 1));

        final regionPath = await _storage.getRegionPath(regionId);

        // Load the region from an existing path using GtfsLocal()
        result = await _local.loadFromPath(
          regionPath,
          repository,
          languageCode: languageCode,
        );

        // Update state based on result
        stateNotifier.value = result.isSuccess ? RegionState.ready : RegionState.error;
        await _saveRegionStatus(
          regionId,
          regionStatus.copyWith(
            isReady: result.isSuccess,
            errorCode: result.errorCode,
            lastUpdated: DateTime.now(),
          ),
        );

        _lastLoadResult = result;

        return result;
      }

      // If region is corrupted, attempt repair
      if (regionStatus.isCorrupted) {
        print("Its corrupted! Attempting repair.");
        final repairError = await _remote.repairRegion(regionId);
        if (repairError == RegionErrorCode.none) {
          // Repair succeeded – region is now ready
          return await loadRegion(regionId);
        } else {
          // Repair failed
          final result = RegionLoadResult.failure(errorCode: repairError);
          stateNotifier.value = RegionState.error;
          await _saveRegionStatus(regionId, regionStatus.copyWith(errorCode: repairError));
          _lastLoadResult = result;
          return result;
        }
      }

      // If region is not downloaded, download it
      if (!regionStatus.isDownloaded) {
        print("Its NOT downloaded!");
        stateNotifier.value = RegionState.downloading;

        final downloadError = await _remote.downloadRegionZip(regionId);
        if (downloadError != RegionErrorCode.none) {
          result = RegionLoadResult.failure(errorCode: downloadError);
          stateNotifier.value = RegionState.error;
          await _saveRegionStatus(regionId, regionStatus.copyWith(errorCode: downloadError));
          _lastLoadResult = result;
          return result;
        }

        // Download successful – mark as downloaded
        await _saveRegionStatus(regionId, regionStatus.copyWith(isDownloaded: true));

        // Proceed to extraction
        stateNotifier.value = RegionState.extracting;
        final extractError = await _remote.extractRegionZip(regionId);
        if (extractError != RegionErrorCode.none) {
          result = RegionLoadResult.failure(errorCode: extractError);
          stateNotifier.value = RegionState.error;
          await _saveRegionStatus(regionId, regionStatus.copyWith(errorCode: extractError));
          _lastLoadResult = result;
          return result;
        }

        // Extraction successful – mark as ready
        await _saveRegionStatus(
          regionId,
          regionStatus.copyWith(isExtracted: true, isReady: true),
        );

        // Re-call loadRegion to load the now-ready region
        return await loadRegion(regionId);
      }

      // If region is downloaded but not extracted
      if (!regionStatus.isExtracted) {
        print("Its downloaded but NOT extracted!");
        stateNotifier.value = RegionState.extracting;

        final extractError = await _remote.extractRegionZip(regionId);
        if (extractError != RegionErrorCode.none) {
          result = RegionLoadResult.failure(errorCode: extractError);
          stateNotifier.value = RegionState.error;
          await _saveRegionStatus(regionId, regionStatus.copyWith(errorCode: extractError));
          _lastLoadResult = result;
          return result;
        }

        // Extraction succeeded – mark as ready
        await _saveRegionStatus(
          regionId,
          regionStatus.copyWith(isExtracted: true, isReady: true),
        );

        // Re-call loadRegion to load the now-ready region
        return await loadRegion(regionId);
      }

      // Fallback: should not reach here
      print("Hm nothing at all?");
      result = RegionLoadResult.failure(errorCode: RegionErrorCode.unknown);
      stateNotifier.value = RegionState.error;
      _lastLoadResult = result;
      return result;
    } catch (e, stack) {
      // Catch any unexpected error
      debugPrint('Unexpected error in loadRegion: $e\n$stack');
      stateNotifier.value = RegionState.error;
      result = RegionLoadResult.failure(
        errorCode: RegionErrorCode.unknown,
        errorMessage: e.toString(),
      );
      await _saveRegionStatus(
        regionId,
        regionStatus.copyWith(errorCode: RegionErrorCode.unknown),
      );
      _lastLoadResult = result;
      return result;
    }
  }

  Future<RegionLoadResult> changeRegion(Region newRegion) async {
    return await loadRegion(newRegion.id);
  }

  /// Sets currentRegionNotifier's value to the region corresponsing to regionId
  /// and saved the id as the last used region
  Future<void> setCurrentRegion(String regionId) async {
    currentRegionNotifier.value = availableRegions.firstWhere(
      (reg) => reg.id == regionId,
    );
    await RegionUtils.saveRegion(regionId);
  }

  // DRAFT DELAY FUNC FOR TESTING
  Future<void> fakeDelay([int s = 2]) async {
    await Future.delayed(Duration(seconds: s));
  }

  Future<void> deleteRegion({String? regionId}) async {
    final String id = regionId ?? currentRegion?.id ?? "";
    if (id.isEmpty) return;
    await _saveRegionStatus(id, RegionStatus(lastUpdated: DateTime.now()));
    await _storage.deleteRegion(id);
    await RegionUtils.deleteSavedRegion();
    print("Succesfully deleted region: $id");
  }
}
