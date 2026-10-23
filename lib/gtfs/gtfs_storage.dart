import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class GtfsStorage {
  static const List<String> coreFiles = [
    "stops.txt",
    "routes.txt",
    "trips.txt",
    "calendar.txt",
    "stop_times.txt",
    "agency.txt"
  ];

  /// Returns the base directory for GTFS data
  Future<Directory> getBaseDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final gtfsDir = Directory('${appDir.path}/gtfs');
    if (!await gtfsDir.exists()) {
      await gtfsDir.create(recursive: true);
    }
    return gtfsDir;
  }

  /// Returns the path for a specific region
  Future<String> getRegionPath(String regionId) async {
    final base = await getBaseDirectory();
    return '${base.path}/$regionId';
  }

  /// Returns the total size of the region directory in bytes
  Future<int> getRegionSize(String regionId) async {
    final path = await getRegionPath(regionId);
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int totalSize = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating size for region $regionId: $e');
    }
    return totalSize;
  }

  /// Checks if a region exists locally (directory exists)
  Future<bool> regionExists(String regionId) async {
    final path = await getRegionPath(regionId);
    return await Directory(path).exists();
  }

  /// Saves the zip file for a region
  Future<void> saveZip(String regionId, List<int> bytes) async {
    final path = await getRegionPath(regionId);
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('$path/gtfs.zip');
    await file.writeAsBytes(bytes);
  }

  /// Checks if the zip file exists for a region
  Future<bool> zipExists(String regionId) async {
    final path = await getRegionPath(regionId);
    final file = File('$path/gtfs.zip');
    return await file.exists();
  }

  /// Reads the zip file for a region
  Future<List<int>> readZip(String regionId) async {
    final path = await getRegionPath(regionId);
    final file = File('$path/gtfs.zip');
    return await file.readAsBytes();
  }

  /// Deletes the zip file for a region
  Future<void> deleteZip(String regionId) async {
    final path = await getRegionPath(regionId);
    final file = File('$path/gtfs.zip');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Extracts the zip file for a region into its directory.
  /// Returns true on success, false on failure.
  Future<bool> extractZip(String regionId) async {
    try {
      final path = await getRegionPath(regionId);
      final zipFile = File('$path/gtfs.zip');
      if (!await zipFile.exists()) {
        debugPrint('Zip file missing for region $regionId');
        return false;
      }
      final zipBytes = await zipFile.readAsBytes();
      return await extractZipToDirectory(path, zipBytes);
    } catch (e) {
      debugPrint('Extraction error for region $regionId: $e');
      return false;
    }
  }

  /// Checks if all core files are extracted. Returns false if at least
  /// one core file is missing.
  Future<bool> verifyCoreFiles(String regionId) async {
    final path = await getRegionPath(regionId);
    final futures = coreFiles.map((file) => File('$path/$file').exists());
    final results = await Future.wait(futures);
    return results.every((exists) => exists);
  }

  /// Deletes the entire region directory.
  Future<void> deleteRegion(String regionId) async {
    final path = await getRegionPath(regionId);
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  // ---- Private low-level utility ----
  /// Extracts a zip file into the target directory.
  /// Returns true on success, false on error.
  Future<bool> extractZipToDirectory(String targetDir, List<int> zipBytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final target = Directory(targetDir);
      if (!await target.exists()) {
        await target.create(recursive: true);
      }

      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name;
          final filePath = '$targetDir/$filename';
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Extraction error: $e');
      return false;
    }
  }
}