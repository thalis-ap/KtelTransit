import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/gtfs/gtfs_storage.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GtfsRemote {
  final GtfsStorage _storage = GtfsStorage();

  static const String _manifestUrl =
      'https://raw.githubusercontent.com/thalis-ap/KtelTransitGtfs/main/manifest.json';

  static const String _regionBaseUrl =
      'https://raw.githubusercontent.com/thalis-ap/KtelTransitGtfs/main/regions/';

  static const String _prefKeyRegionHashes = 'gtfs_region_hashes';
  static const String _prefKeyManifestVersion = 'gtfs_manifest_version';
  static const String _prefKeyRegionExtracted = 'gtfs_region_extracted';

  // ----- Public Methods -----

  /// Checks if the remote manifest has a newer version than the locally stored one.
  Future<bool> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(_manifestUrl));
      if (response.statusCode != 200) return false;

      final manifest = jsonDecode(response.body);
      final remoteVersion = manifest['version'] as String;

      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString(_prefKeyManifestVersion) ?? '';

      return remoteVersion != localVersion;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Fetches the full manifest.json from the repository.
  Future<Map<String, dynamic>?> getManifest() async {
    try {
      final response = await http.get(Uri.parse(_manifestUrl));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching manifest: $e');
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

  /// Returns the stored hash for a region, if any.
  Future<String?> getStoredHash(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHashes = prefs.getString(_prefKeyRegionHashes) ?? '{}';
    final Map<String, String> hashes = Map<String, String>.from(
      jsonDecode(storedHashes) as Map,
    );
    return hashes[regionId];
  }

  /// Returns the stored manifest version.
  Future<String?> getStoredManifestVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyManifestVersion);
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
    // Step 1: Check if zip exists
    final zipExists = await _storage.zipExists(regionId);

    if (zipExists) {
      // Step 2: Try to extract the existing zip
      final extractError = await extractRegionZip(regionId);
      if (extractError == RegionErrorCode.none) {
        return RegionErrorCode.none; // Repair succeeded
      }
      // Extraction failed – we'll re-download
      debugPrint('Extraction failed during repair for $regionId: $extractError');
    }

    // Step 3: Full re-download and extract
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