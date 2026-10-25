import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';

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

// TODO We should probably merge RegionMetadata with Region since we are loading regions from remote manifest (a manifest in general) that contains hash + size attr
class RegionMetadata {
  final String hash;
  final int size;

  const RegionMetadata({required this.hash, required this.size});
}

class Region {
  final String id;
  final String name, englishName;
  final LatLng center;
  // depends on how large the area is bigger area -> smaller zoom
  final double defaultZoom;

  const Region({
    required this.id,
    required this.name,
    required this.englishName,
    required this.center,
    required this.defaultZoom,
  });

  String getLocalizedName(String languageCode) {
    return languageCode == 'en' ? englishName : name;
  }

  factory Region.fromJson(String id, Map<String, dynamic> json) {
    final centerList = json['center'] as List;
    return Region(
      id: id,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      center: LatLng(
        (centerList[0] as num).toDouble(),
        (centerList[1] as num).toDouble(),
      ),
      defaultZoom: (json['defaultZoom'] as num).toDouble(),
    );
  }
}