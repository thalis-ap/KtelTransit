import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/gtfs/gtfs_preferences.dart';
import 'package:ktel_transit/gtfs/gtfs_storage.dart';

import '../models/extras/region.dart';

class ManifestConfig {
  /// The main manifest - source of truth, url
  static const String manifestUrl =
      'https://raw.githubusercontent.com/thalis-ap/KtelTransitGtfs/main/manifest.json';

  /// Base url for a region path
  static const String regionBaseUrl =
      'https://raw.githubusercontent.com/thalis-ap/KtelTransitGtfs/main/regions/';

  /// Manifest keys
  static const String regionsKey = 'regions';
  static const String versionKey = 'version';

  /// Region metadata
  static const String nameKey = 'name';
  static const String englishNameKey = 'englishName';
  static const String centerKey = 'center';
  static const String defaultZoomKey = 'defaultZoom';
  static const String hashKey = 'hash';
  static const String sizeKey = 'size';
}

class GtfsRemote {


  final GtfsStorage _storage = GtfsStorage();
  final GtfsPreferences _prefs = GtfsPreferences();

  /// The manifest that we are currently loading (in a Future). We are using this
  /// in order to await for the same future, i.e. the one loading the remote
  /// manifest from the network, and not create a new one that fetches the same
  Future<Map<String, dynamic>?>? _manifestInFlight;

  /// This is the result of the last manifest fetch. Once we load it once, we
  /// can access the remote manifest through it.
  Map<String, dynamic>? _manifestCache;

  /// This function makes sure that callers will not await for multiple instances
  /// of the same remote manifest. Once a remoteManifest starts being fetched
  /// _manifestInFlight becomes the future waiting for the result. Consequent
  /// calls to the function will return the same future, thus every caller
  /// will wait for the same result without spawning new fetch calls.
  /// If the fetching succeeds before any subsequent calls to the function,
  /// _manifestCache takes over and instantly returns the last fetched manifest.
  /// [forceRefresh] bypasses both in-flight and cache and continues to fetch
  /// a brand new manifest from the network.
  Future<Map<String, dynamic>?> getManifest({bool forceRefresh = false}) async {
    // We already have the remote manifest cached
    if (!forceRefresh && _manifestCache != null) return _manifestCache;

    /* The future is already set. Just return it so we can await for the same
     * result
     */
    if (!forceRefresh && _manifestInFlight != null) return _manifestInFlight;

    /* At this point we have no remote manifest, neither cached not in flight.
     * We should initialize the fetching ourselves.
     */
    _manifestInFlight = _fetchManifest();
    try {
      final result = await _manifestInFlight;
      if (result != null) _manifestCache = result;
      return result;
    } finally {
      _manifestInFlight = null;
    }
  }

  /// Fetches the manifest from the network and caches it locally.
  Future<Map<String, dynamic>?> _fetchManifest() async {
    try {
      // Use a timeout so that in case the network is slow we give up instead of
      // hanging on the splash screen
      final response = await http
          .get(Uri.parse(ManifestConfig.manifestUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final jsonStr = response.body;
      await _prefs.cacheManifestJson(jsonStr);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching manifest: $e');
      return null;
    }
  }

  /// Returns a list of region ids which must be updated. This means that their
  /// remote hash fetched from the manifest is different from the locally stored
  /// one. If [manifest] is passed in there is no need to call getManifest()
  Future<List<String>> getRegionsThatNeedUpdate({
    Map<String, dynamic>? manifest,
  }) async {
    try {
      final remoteManifest = manifest ?? await getManifest();

      // Silently fail if we cannot get the remoteManifest
      if (remoteManifest == null) return [];

      // Deliberately always diff hashes here rather than short-circuiting
      // on remoteManifest version. extractRegionZip() only stamps a region's
      // hash (and the remoteManifest version) once IT successfully extracts, so
      // if a previous update run got interrupted partway through, some
      // downloaded regions can still be stale even though the remoteManifest
      // version already matches. Per-region hash comparison stays correct
      // no matter how a previous run ended, and self-heals on retry.
      final List<String> changedIds = [];
      for (Region region in getAvailableRegionsFromManifest(remoteManifest)) {
        // Found a region with a different hash
        if (region.metadata.hash != await _prefs.getRegionHash(region.id)) {
          changedIds.add(region.id);
        }
      }

      return changedIds;
    } catch (e) {
      debugPrint('Error checking for regions that need update: $e');
      return [];
    }
  }

  /// This function returns the region that a given manifest contains
  List<Region> getAvailableRegionsFromManifest(Map<String, dynamic> manifest) {
    final regions = manifest[ManifestConfig.regionsKey] as Map<String, dynamic>?;
    if (regions == null) return [];

    return regions.entries.map((entry) {
      return Region.fromJson(entry.key, entry.value);
    }).toList();
  }

  /// Downloads only the GTFS zip file for the given region.
  /// Does not extract, nor update preferences.
  Future<RegionErrorCode> downloadRegionZip(String regionId) async {
    try {
      final zipUrl = '${ManifestConfig.regionBaseUrl}$regionId/gtfs.zip';
      final zipResponse = await http.get(Uri.parse(zipUrl));

      if (zipResponse.statusCode != 200) {
        debugPrint(
          'Failed to download zip for $regionId: ${zipResponse.statusCode}',
        );
        return RegionErrorCode.downloadFailed;
      }

      // Delegate file writing to storage
      await _storage.saveZip(regionId, zipResponse.bodyBytes);
      debugPrint('Downloaded zip for region $regionId');
      return RegionErrorCode.none;
    } on SocketException catch (e) {
      debugPrint('Network error downloading $regionId: $e');
      return RegionErrorCode.network;
    } on http.ClientException catch (e) {
      debugPrint('HTTP client error downloading $regionId: $e');
      return RegionErrorCode.network;
    } on FileSystemException catch (e) {
      debugPrint('File system error downloading $regionId: $e');
      return RegionErrorCode.storageFull;
    } catch (e) {
      debugPrint('Unexpected error downloading $regionId: $e');
      return RegionErrorCode.unknown;
    }
  }

  /// Extracts an already downloaded GTFS zip for the given region.
  /// Verifies core files exist, updates stored hash and manifest version,
  /// and optionally deletes the zip file after successful extraction.
  /// Returns error code.
  Future<RegionErrorCode> extractRegionZip(
    String regionId, {
    bool deleteZipAfter = true,
  }) async {
    try {
      // Extract using storage
      final extracted = await _storage.extractZip(regionId);
      if (!extracted) {
        debugPrint('Extraction failed for $regionId');
        return RegionErrorCode.extractionFailed;
      }

      // Verify core files
      if (!await _storage.verifyCoreFiles(regionId)) {
        debugPrint('Extraction incomplete (missing core files) for $regionId');
        return RegionErrorCode.missingFiles;
      }

      // Fetch manifest to get current hash and version
      final manifest = await getManifest();
      if (manifest == null) {
        debugPrint('Could not fetch manifest for hash update');
        return RegionErrorCode.unknown;
      }

      final regionData = manifest[ManifestConfig.regionsKey][regionId];
      if (regionData == null) {
        debugPrint('Region $regionId not found in manifest');
        return RegionErrorCode.unknown;
      }

      final remoteHash = regionData[ManifestConfig.hashKey] as String;
      final remoteVersion = manifest[ManifestConfig.versionKey] as String;

      // Update preferences
      await _prefs.saveRegionHash(regionId, remoteHash);
      await _prefs.saveManifestVersion(remoteVersion);
      await _prefs.markRegionExtracted(regionId);

      // Optionally delete zip
      if (deleteZipAfter) {
        await _storage.deleteZip(regionId);
      }

      debugPrint('Successfully extracted region $regionId');
      return RegionErrorCode.none;
    } on FileSystemException catch (e) {
      debugPrint('File system error extracting $regionId: $e');
      return RegionErrorCode.storageFull;
    } catch (e) {
      debugPrint('Error extracting region $regionId: $e');
      return RegionErrorCode.unknown;
    }
  }

  /// Downloads ALL regions from the manifest.
  /// Returns the number of successfully downloaded and extracted regions.
  Future<int> downloadAllRegions() async {
    final manifest = await getManifest();
    if (manifest == null) return 0;

    final regions = manifest[ManifestConfig.regionsKey] as Map<String, dynamic>;
    int successCount = 0;

    for (final regionId in regions.keys) {
      final downloaded = await downloadRegionZip(regionId);
      if (downloaded != RegionErrorCode.none) continue;

      final extracted = await extractRegionZip(regionId);
      if (extracted == RegionErrorCode.none) successCount++;
    }

    return successCount;
  }

  /// Clears all locally stored GTFS data and preferences (for testing or reset).
  Future<void> clearAllData() async {
    await _prefs.clearAllGtfsPreferences();

    // Storage deletion: we need to delete the whole gtfs directory.
    // We can add a method in storage to clear everything.
    final base = await _storage.getBaseDirectory();
    if (await base.exists()) {
      await base.delete(recursive: true);
    }
    debugPrint('Cleared all GTFS data');
  }

  // ----- Repair and Recovery -----

  /// Repairs a corrupted region.
  /// - If a zip file exists, attempts to extract it.
  /// - If extraction fails or zip is missing, deletes the region and re‑downloads + extracts.
  /// Returns `RegionErrorCode.none` on success, or the first error encountered.
  Future<RegionErrorCode> repairRegion(String regionId) async {
    // Check if zip exists
    final zipExists = await _storage.zipExists(regionId);

    if (zipExists) {
      // Try to extract the existing zip
      final extractError = await extractRegionZip(regionId);
      if (extractError == RegionErrorCode.none) {
        return RegionErrorCode.none; // Repair succeeded
      }
      // Extraction failed – we'll re-download
      debugPrint(
        'Extraction failed during repair for $regionId: $extractError',
      );
    }

    // Full re-download and extract
    debugPrint('Re-downloading region $regionId for repair');

    // Delete existing region files to start fresh
    await _storage.deleteRegion(regionId);

    // Download
    final downloadError = await downloadRegionZip(regionId);
    if (downloadError != RegionErrorCode.none) {
      return downloadError;
    }

    // Extract
    final extractError2 = await extractRegionZip(regionId);
    return extractError2; // returns none on success
  }
}
