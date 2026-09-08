import 'dart:async';
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

  final GtfsStorage _storage = GtfsStorage();

  final GtfsLocal _local = GtfsLocal();
  final GtfsRemote _remote = GtfsRemote();

  final GtfsRepository _repository = GtfsRepository();

  // ---- State Notifiers ----
  final CustomValueNotifier<Region?> currentRegionNotifier =
  CustomValueNotifier(null);

  final CustomValueNotifier<RegionState> stateNotifier =
  CustomValueNotifier<RegionState>(RegionState.idle);

  final CustomValueNotifier<double> progressNotifier =
  CustomValueNotifier<double>(0.0);

  /// Bumped every time any region's status changes. UI that lists regions
  /// (e.g. RegionSearchDelegate) can listen to this to silently refresh
  /// itself when a background sync updates a region it isn't currently
  /// showing a dedicated loading state for.
  final CustomValueNotifier<int> regionStatusVersion =
  CustomValueNotifier<int>(0);

  /// Tracks in-progress download+extract operations per region so that a
  /// background sync and a foreground load/refresh for the same region
  /// never run concurrently and race on the same files on disk.
  final Map<String, Future<RegionErrorCode>> _inFlightSyncs = {};

  // ---- Per-Region Status Cache ----
  final Map<String, RegionStatus> _regionStatusCache = {};

  RegionLoadResult? _lastLoadResult;

  // Getter for quick access
  Region? get currentRegion => currentRegionNotifier.value;

  GtfsRepository get repository => _repository;
  GtfsStorage get storage => _storage;

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

    if (await _remote.checkForUpdates()) {
      handleUpdates();
    }


    _isInitialized = true;
  }

  // Updates

  /// Kicks off updates for every region whose remote hash has changed,
  /// skipping regions that were never downloaded (they'll simply fetch the
  /// latest zip the next time someone selects them via [loadRegion]).
  ///
  /// Non-current regions are synced silently in the background: only their
  /// on-disk status changes, which is enough for anything listening to
  /// [regionStatusVersion] (e.g. the region picker) to refresh its icons.
  ///
  /// The current region is also synced silently — we deliberately avoid
  /// touching [stateNotifier] here so nothing visibly interrupts whatever
  /// the user is doing. Once the new files are safely on disk we hot-swap
  /// them into the live [repository], but only if the user is still on
  /// that region by the time the sync finishes.
  ///
  /// This method intentionally doesn't await every sync before returning —
  /// call it fire-and-forget, as [init] already does. Nothing here touches
  /// the global loading state, so the app never blocks on it.
  Future<void> handleUpdates() async {
    final idsThatNeedUpdate = await _remote.getRegionsThatNeedUpdate();
    if (idsThatNeedUpdate.isEmpty) return;

    debugPrint('Regions needing update: $idsThatNeedUpdate');

    for (final id in idsThatNeedUpdate) {
      // Skip regions nobody has downloaded — nothing to refresh.
      final status = _regionStatusCache[id];
      final hasData = (status?.isDownloaded ?? false) || (status?.isReady ?? false);

      // Skip regions nobody has downloaded or readied — nothing to refresh.
      if (!hasData) {
        debugPrint('Skipping update for $id: Region is neither downloaded nor ready.');
        continue;
      }

      if (id == currentRegion?.id) {
        unawaited(_refreshCurrentRegionInPlace(id));
      } else {
        unawaited(_updateRegionSilently(id));
      }
    }
  }

  /// Silently re-downloads and re-extracts [regionId] in the background.
  /// Only updates the persisted/cached [RegionStatus] — never touches the
  /// global [stateNotifier], since this region isn't the one currently
  /// being shown to the user.
  Future<void> _updateRegionSilently(String regionId) async {
    final errorCode = await _syncRegion(regionId, foreground: false);
    if (errorCode != RegionErrorCode.none) {
      // Old data on disk is untouched and still perfectly usable — just
      // log it and try again on the next update check.
      debugPrint('Silent background update failed for $regionId: $errorCode');
    }
  }

  /// Like [_updateRegionSilently], but for the region the user currently
  /// has open. After a successful sync, reloads the fresh files into the
  /// live [repository] so the change is picked up without a visible
  /// reload — unless the user has since switched to a different region,
  /// in which case we leave the in-memory data alone (the fresh files are
  /// already safely on disk and will load normally next time that region
  /// is selected).
  Future<void> _refreshCurrentRegionInPlace(String regionId) async {
    final errorCode = await _syncRegion(regionId, foreground: false);
    if (errorCode != RegionErrorCode.none) {
      debugPrint('Background refresh of current region $regionId failed: $errorCode');
      return;
    }

    if (_settingsController == null || currentRegion?.id != regionId) return;

    final languageCode = _settingsController!.locale.languageCode;
    final regionPath = await _storage.getRegionPath(regionId);
    final result = await _local.loadFromPath(
      regionPath,
      repository,
      languageCode: languageCode,
    );

    if (result.isSuccess) {
      _lastLoadResult = result;
      debugPrint('Region $regionId data refreshed in place.');
    } else {
      debugPrint('Hot-swap reload failed for $regionId: ${result.errorCode}');
    }
  }

  /// Downloads (unless [skipDownload]) and extracts [regionId], persisting
  /// status/error info as it goes. Concurrent calls for the same region
  /// share the same underlying operation instead of racing on disk — e.g.
  /// a background sync and a manual reload of the same region will simply
  /// await the same [Future] rather than both writing to the same files.
  ///
  /// When [foreground] is true, [stateNotifier] is updated so an active
  /// screen can reflect progress; when false, this runs silently.
  Future<RegionErrorCode> _syncRegion(
      String regionId, {
        bool foreground = false,
        bool skipDownload = false,
      }) {
    final inFlight = _inFlightSyncs[regionId];
    if (inFlight != null) return inFlight;

    final future = _runSync(regionId, foreground: foreground, skipDownload: skipDownload);
    _inFlightSyncs[regionId] = future;
    future.whenComplete(() => _inFlightSyncs.remove(regionId));
    return future;
  }

  Future<RegionErrorCode> _runSync(
      String regionId, {
        required bool foreground,
        bool skipDownload = false,
      }) async {
    if (!skipDownload) {
      if (foreground) stateNotifier.value = RegionState.downloading;

      final downloadError = await _remote.downloadRegionZip(regionId);
      if (downloadError != RegionErrorCode.none) {
        if (foreground) stateNotifier.value = RegionState.error;
        await _saveRegionStatus(
          regionId,
          getRegionStatus(regionId).copyWith(errorCode: downloadError),
        );
        return downloadError;
      }

      await _saveRegionStatus(
        regionId,
        getRegionStatus(regionId).copyWith(isDownloaded: true),
      );
    }

    if (foreground) stateNotifier.value = RegionState.extracting;

    final extractError = await _remote.extractRegionZip(regionId);
    if (extractError != RegionErrorCode.none) {
      if (foreground) stateNotifier.value = RegionState.error;
      await _saveRegionStatus(
        regionId,
        getRegionStatus(regionId).copyWith(errorCode: extractError),
      );
      return extractError;
    }

    await _saveRegionStatus(
      regionId,
      getRegionStatus(regionId).copyWith(
        isExtracted: true,
        isReady: true,
        errorCode: RegionErrorCode.none,
        lastUpdated: DateTime.now(),
      ),
    );

    return RegionErrorCode.none;
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

    // Let anything listening (e.g. the region picker) know a status
    // changed, without needing to know which region or what changed.
    regionStatusVersion.value++;
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
  ///
  /// Pass [forceRefresh]: true to re-sync even if the region is already
  /// marked ready (e.g. a manual "check for updates" action). This always
  /// runs in the foreground (stateNotifier reflects progress) since the
  /// caller is explicitly asking to wait for it.
  Future<RegionLoadResult> loadRegion(String regionId, {bool forceRefresh = false}) async {
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
      // If region is already ready, load from local storage — unless a
      // refresh was explicitly requested, in which case fall through and
      // re-sync first.
      if (regionStatus.isReady && !forceRefresh) {
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

      // If region is not downloaded (or a refresh was forced), sync it.
      // _syncRegion also protects us if a background update for this same
      // region happens to already be in flight — we'll just await it
      // instead of racing a second download/extract on the same files.
      if (!regionStatus.isDownloaded || forceRefresh) {
        print(forceRefresh ? "Forcing a refresh!" : "Its NOT downloaded!");

        final errorCode = await _syncRegion(regionId, foreground: true);
        if (errorCode != RegionErrorCode.none) {
          result = RegionLoadResult.failure(errorCode: errorCode);
          _lastLoadResult = result;
          return result;
        }

        // Re-call loadRegion to load the now-ready region
        return await loadRegion(regionId);
      }

      // If region is downloaded but not extracted (e.g. a previous
      // extraction was interrupted), extract without re-downloading.
      if (!regionStatus.isExtracted) {
        print("Its downloaded but NOT extracted!");

        final errorCode = await _syncRegion(regionId, foreground: true, skipDownload: true);
        if (errorCode != RegionErrorCode.none) {
          result = RegionLoadResult.failure(errorCode: errorCode);
          _lastLoadResult = result;
          return result;
        }

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

    final isCurrentRegion = (id == currentRegion?.id);

    // If deleting the active region, show the loading sheet
    if (isCurrentRegion) {
      stateNotifier.value = RegionState.deleting;
    }

    // Wipe the data
    await _saveRegionStatus(id, const RegionStatus());
    await _storage.deleteRegion(id);

    if (isCurrentRegion) {
      await RegionUtils.deleteSavedRegion();
      repository.clear();

      // Add a tiny delay so the user actually sees the "Deleting..." sheet
      // before it instantly vanishes and throws them to the Welcome Screen.
      await Future.delayed(const Duration(seconds: 1));

      currentRegionNotifier.value = null;
      stateNotifier.value = RegionState.idle;
    }

    debugPrint("Succesfully deleted region: $id");
  }
}