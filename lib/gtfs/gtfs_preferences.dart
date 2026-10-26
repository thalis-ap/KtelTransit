import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/extras/region.dart';

/// Every SharedPreferences-backed piece of GTFS state lives here.
class GtfsPreferences {
  static const String _prefKeyRegionHashes     = 'gtfs_region_hashes';
  static const String _prefKeyManifestJson     = 'gtfs_manifest_json';
  static const String _prefKeyManifestVersion  = 'gtfs_manifest_version';
  static const String _prefKeyRegionExtracted  = 'gtfs_region_extracted';
  static const String _prefKeyRegionStatuses   = 'region_statuses';

  // ---- Manifest cache ----
  Future<bool> hasCachedManifest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefKeyManifestJson);
  }

  Future<Map<String, dynamic>?> getCachedManifest() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeyManifestJson);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding cached manifest: $e');
      return null;
    }
  }

  Future<void> cacheManifestJson(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyManifestJson, jsonStr);
  }

  // ---- Manifest version ----
  Future<String?> getManifestVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyManifestVersion);
  }

  Future<void> saveManifestVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyManifestVersion, version);
  }

  // ---- Region hashes ----
  Future<String?> getRegionHash(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    return _readHashes(prefs)[regionId];
  }

  Future<void> saveRegionHash(String regionId, String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final hashes = _readHashes(prefs);
    hashes[regionId] = hash;
    await prefs.setString(_prefKeyRegionHashes, jsonEncode(hashes));
  }

  Map<String, String> _readHashes(SharedPreferences prefs) {
    final raw = prefs.getString(_prefKeyRegionHashes) ?? '{}';
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  // ---- Region extracted flag ----
  Future<void> markRegionExtracted(String regionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefKeyRegionExtracted}_$regionId', true);
  }

  // ---- Per-region status ----
  Future<Map<String, RegionStatus>> loadRegionStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyRegionStatuses);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((id, v) =>
          MapEntry(id, RegionStatus.fromJson(v as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Error loading region statuses: $e');
      return {};
    }
  }

  Future<void> saveRegionStatuses(Map<String, RegionStatus> statuses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
    statuses.map((id, s) => MapEntry(id, s.toJson()));
    await prefs.setString(_prefKeyRegionStatuses, jsonEncode(encoded));
  }

  // ---- Reset ----
  Future<void> clearAllGtfsPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRegionHashes);
    await prefs.remove(_prefKeyManifestVersion);
    await prefs.remove(_prefKeyRegionExtracted);
    // Deliberately keeping _prefKeyManifestJson (matches old clearAllData)
    // and _prefKeyRegionStatuses (managed by GtfsManager).
  }
}