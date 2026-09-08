import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/gtfs/gtfs_storage.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/region.dart';

class GtfsRemote {
  final GtfsStorage _storage = GtfsStorage();

  /// The main manifest - source of truth, url
  static const String _manifestUrl =
      'https://raw.githubusercontent.com/thalis-ap/KtelTransitGtfs/main/manifest.json';

  /// Base url for a region path
  static const String _regionBaseUrl =
      'https://raw.githubusercontent.com/thalis-ap/KtelTransitGtfs/main/regions/';

  static const String _prefKeyRegionHashes = 'gtfs_region_hashes';
  static const String _prefKeyManifestJson = 'gtfs_manifest_json';
  static const String _prefKeyManifestVersion = 'gtfs_manifest_version';
  static const String _prefKeyRegionExtracted = 'gtfs_region_extracted';


  // ----- Public Methods -----

  /// Checks if the remote manifest has a newer version than the locally stored one.
  /// This function does not initiate updates, but rather returns true/false
  /// if there are/aren't new data.
  Future<bool> checkForUpdates() async {
    try {
      final manifest = await getManifest();

      // Silently fail if we cannot get the manifest
      if (manifest == null) return false;

      final remoteVersion = manifest['version'] as String;
      print("Remote manifest version is: $remoteVersion");

      return remoteVersion != await getLocalManifestVersion();
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Returns a list of region ids which must be updated. This means that their
  /// remote hash fetched from the manifest is different from the locally stored
  /// one.
  Future<List<String>> getRegionsThatNeedUpdate() async {
    try {
      final manifest = await getManifest();

      // Silently fail if we cannot get the manifest
      if (manifest == null) return [];

      // Deliberately always diff hashes here rather than short-circuiting
      // on manifest version. extractRegionZip() only stamps a region's
      // hash (and the manifest version) once IT successfully extracts, so
      // if a previous update run got interrupted partway through, some
      // downloaded regions can still be stale even though the manifest
      // version already matches. Per-region hash comparison stays correct
      // no matter how a previous run ended, and self-heals on retry.
      final List<String> changedIds = [];
      for (Region region in getAvailableRegionsFromManifest(manifest)) {
        final RegionMetadata? metadata = getRegionMetadata(manifest, region.id);
        if (metadata == null) continue;

        // Found a region with a different hash
        if (metadata.hash != await getLocalHash(region.id)) {
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
    final regions = manifest['regions'] as Map<String, dynamic>?;
    if (regions == null) return [];

    return regions.entries.map((entry) {
      return Region.fromJson(entry.key, entry.value);
    }).toList();
  }

  RegionMetadata? getRegionMetadata(Map<String, dynamic> manifest, String regionId) {
    final regions = manifest['regions'] as Map<String, dynamic>?;
    if (regions == null) return null;

    final data = regions[regionId];
    if (data == null) return null;
    return RegionMetadata(hash: data['hash'] as String, size: data['size'] as int);
  }

  /// Fetches the manifest from the network and caches it locally.
  Future<Map<String, dynamic>?> getManifest() async {
    try {
      final response = await http.get(Uri.parse(_manifestUrl));
      if (response.statusCode != 200) return null;

      final jsonStr = response.body;

      // Cache the raw JSON string so it's available offline next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyManifestJson, jsonStr);

      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching manifest: $e');
      return null;
    }
  }

  /// Loads the most recently cached manifest from local storage.
  Future<Map<String, dynamic>?> getCachedManifest() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeyManifestJson);
    if (jsonStr != null) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return null;
  }

  /// Loads the emergency fallback manifest bundled with the app.
  Future<Map<String, dynamic>?> getFallbackManifest() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/gtfs/manifest_fallback.json');
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('No fallback manifest found: $e');
      return null;
    }
  }

  /// Downloads only the GTFS zip file for the given region.
  /// Does not extract, nor update preferences.
  Future<RegionErrorCode> downloadRegionZip(String regionId) async {
    try {
      final zipUrl = '$_regionBaseUrl$regionId/gtfs.zip';
      final zipResponse = await http.get(Uri.parse(zipUrl));

      if (zipResponse.statusCode != 200) {
        debugPrint('Failed to download zip for $regionId: ${zipResponse.statusCode}');
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

      final regionData = manifest['regions'][regionId];
      if (regionData == null) {
        debugPrint('Region $regionId not found in manifest');
        return RegionErrorCode.unknown;
      }

      final remoteHash = regionData['hash'] as String;
      final remoteVersion = manifest['version'] as String;

      // Update preferences
      final prefs = await SharedPreferences.getInstance();
      final storedHashes = prefs.getString(_prefKeyRegionHashes) ?? '{}';
      final Map<String, String> hashes = Map<String, String>.from(
        jsonDecode(storedHashes) as Map,
      );
      hashes[regionId] = remoteHash;
      await prefs.setString(_prefKeyRegionHashes, jsonEncode(hashes));
      await prefs.setString(_prefKeyManifestVersion, remoteVersion);
      await prefs.setBool('${_prefKeyRegionExtracted}_$regionId', true);

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

    final regions = manifest['regions'] as Map<String, dynamic>;
    int successCount = 0;

    for (final regionId in regions.keys) {
      final downloaded = await downloadRegionZip(regionId);
      if (downloaded != RegionErrorCode.none) continue;

      final extracted = await extractRegionZip(regionId);
      if (extracted == RegionErrorCode.none) successCount++;
    }

    return successCount;
  }

  /// Returns the local hash for a region, if any.
  Future<String?> getLocalHash(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    final localHashes = prefs.getString(_prefKeyRegionHashes) ?? '{}';
    final Map<String, String> hashes = Map<String, String>.from(
      jsonDecode(localHashes) as Map,
    );
    return hashes[regionId];
  }

  /// Returns the local manifest version.
  Future<String?> getLocalManifestVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyManifestVersion);
  }

  /// Saved the new manifest version locally
  Future<void> saveLocalManifestVersion(String newVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyManifestVersion, newVersion);
  }

  /// Clears all locally stored GTFS data and preferences (for testing or reset).
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRegionHashes);
    await prefs.remove(_prefKeyManifestVersion);
    await prefs.remove(_prefKeyRegionExtracted);

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
      debugPrint('Extraction failed during repair for $regionId: $extractError');
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