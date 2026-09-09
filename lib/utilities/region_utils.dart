import 'package:flutter/material.dart';
import 'package:ktel_transit/gtfs/gtfs_manager.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/region.dart';
import '../delegates/region_search_delegate.dart';

enum RegionState {
  idle, // Nothing happening
  downloading, // Downloading a zip file
  extracting, // Extracting a zip file
  loading, // Loading GTFS files into repository
  ready, // Data loaded and ready
  error, // Something went wrong
  deleting, // Region is being deleted
  changingLocale, // Changing locale for the current region
}

enum RegionErrorCode {
  none,
  network, // No internet or timeout
  downloadFailed, // HTTP error
  extractionFailed, // Zip corrupt or extraction error
  missingFiles, // Required files missing after extraction
  parsingFailed, // CSV parsing error
  storageFull, // Not enough disk space
  unknown, // Catch-all
}

class RegionLoadResult {
  final bool success;
  final RegionErrorCode errorCode;
  final String? errorMessage;

  const RegionLoadResult({
    required this.success,
    this.errorCode = RegionErrorCode.none,
    this.errorMessage,
  });

  // Convenience factories
  factory RegionLoadResult.success() => const RegionLoadResult(success: true);

  factory RegionLoadResult.failure({
    RegionErrorCode errorCode = RegionErrorCode.unknown,
    String? errorMessage,
  }) {
    return RegionLoadResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  factory RegionLoadResult.missingFiles({String? errorMessage}) {
    return RegionLoadResult(
      success: false,
      errorCode: RegionErrorCode.missingFiles,
      errorMessage: errorMessage,
    );
  }

  factory RegionLoadResult.parsingFailed({String? errorMessage}) {
    return RegionLoadResult(
      success: false,
      errorCode: RegionErrorCode.parsingFailed,
      errorMessage: errorMessage,
    );
  }

  factory RegionLoadResult.unknownError({String? errorMessage}) {
    return RegionLoadResult(
      success: false,
      errorCode: RegionErrorCode.unknown,
      errorMessage: errorMessage,
    );
  }

  String getErrorString(AppLocalizations l10n) {
    switch (errorCode) {
      case RegionErrorCode.none:
        return '';
      case RegionErrorCode.network:
        return l10n.regionErrorNetwork;
      case RegionErrorCode.downloadFailed:
        return l10n.regionErrorDownloadFailed;
      case RegionErrorCode.extractionFailed:
        return l10n.regionErrorExtractionFailed;
      case RegionErrorCode.missingFiles:
        return l10n.regionErrorMissingFiles;
      case RegionErrorCode.parsingFailed:
        return l10n.regionErrorParsingFailed;
      case RegionErrorCode.storageFull:
        return l10n.regionErrorStorageFull;
      case RegionErrorCode.unknown:
        return l10n.regionErrorUnknown;
    }
  }

  // Success check
  bool get isSuccess => success;

  bool get isFailure => !success;
}

class RegionStatus {
  final bool isDownloaded;
  final bool isExtracted;
  final bool isCorrupted;
  final bool isReady;
  final DateTime? lastUpdated;
  final RegionErrorCode errorCode;

  const RegionStatus({
    this.isDownloaded = false,
    this.isExtracted = false,
    this.isCorrupted = false,
    this.isReady = false,
    this.lastUpdated,
    this.errorCode = RegionErrorCode.none,
  });

  bool get isEmpty {
    return !isDownloaded &&
        !isExtracted &&
        !isCorrupted &&
        !isReady &&
        errorCode == RegionErrorCode.none &&
        lastUpdated == null;
  }

  Map<String, dynamic> toJson() => {
    'isDownloaded': isDownloaded,
    'isExtracted': isExtracted,
    'isCorrupted': isCorrupted,
    'isReady': isReady,
    'lastUpdated': lastUpdated?.toIso8601String(),
    'errorCode': errorCode.index,
  };

  factory RegionStatus.fromJson(Map<String, dynamic> json) {
    return RegionStatus(
      isDownloaded: json['isDownloaded'] ?? false,
      isExtracted: json['isExtracted'] ?? false,
      isCorrupted: json['isCorrupted'] ?? false,
      isReady: json['isReady'] ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      errorCode: json['errorCode'] != null
          ? RegionErrorCode.values[json['errorCode']]
          : RegionErrorCode.none,
    );
  }

  RegionStatus copyWith({
    bool? isDownloaded,
    bool? isExtracted,
    bool? isCorrupted,
    bool? isReady,
    DateTime? lastUpdated,
    RegionErrorCode? errorCode,
  }) {
    return RegionStatus(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isExtracted: isExtracted ?? this.isExtracted,
      isCorrupted: isCorrupted ?? this.isCorrupted,
      isReady: isReady ?? this.isReady,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}

class RegionUtils {
  static const String savedRegionIdKey = "saved_region_id";

  static Future<String?> getSavedRegion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(RegionUtils.savedRegionIdKey);
  }

  static Future<void> saveRegion(String regionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(RegionUtils.savedRegionIdKey, regionId);
  }

  static Future<void> deleteSavedRegion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(RegionUtils.savedRegionIdKey);
  }

  /// We use beforeAction and afterAction to customize functionality depending
  /// on which calls the function. See routes_screen.dart difference compared to
  /// home_screen.dart use for example.
  static Future<RegionLoadResult?> promptRegionChange(
    BuildContext context,
    GtfsManager gtfsManager, {
    required VoidCallback beforeAction,
    void Function(Region)? onSelectedAction,
    VoidCallback? afterAction,
  }) async {
    // Calls the 'before actions'
    beforeAction.call();

    // Open the region search screen directly over whatever page the user is currently on
    final selectedRegion = await showSearch<Region?>(
      context: context,
      delegate: RegionSearchDelegate(
        searchFieldLabel: AppLocalizations.of(context)!.searchRegionHint,
        gtfsManager: gtfsManager,
      ),
    );

    RegionLoadResult? res;

    // Check if they picked a valid region
    if (selectedRegion != null && context.mounted) {
      // Calls the 'after' actions
      onSelectedAction?.call(selectedRegion);


      // Change the region (which automatically commands the map to fly there)
      res = await gtfsManager.changeRegion(selectedRegion.id);
    }

    afterAction?.call();

    return res;
  }
}
