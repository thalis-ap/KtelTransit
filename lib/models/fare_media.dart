/// The kind of medium a fare product can be bought on / validated with,
/// as defined by fare_media.txt (fare_media_type). Any value outside the
/// spec's range maps to [unknown] instead of rejecting the row.
enum FareMediaType {
  none, // 0 - no medium needed (e.g. pay the driver)
  paperTicket, // 1
  transitCard, // 2
  contactlessEmv, // 3
  mobileApp, // 4
  unknown;

  /// Transforms gtfs values of 0,1,2,3,4 to FareMediaType enum respectively
  static FareMediaType fromGtfsValue(String gtfsValue) {
    switch (gtfsValue) {
      case '0':
        return FareMediaType.none;
      case '1':
        return FareMediaType.paperTicket;
      case '2':
        return FareMediaType.transitCard;
      case '3':
        return FareMediaType.contactlessEmv;
      case '4':
        return FareMediaType.mobileApp;
      default:
        return FareMediaType.unknown;
    }
  }
}

/// A way of paying for / validating a fare product (paper ticket, transit
/// card, mobile app, ...). See fare_media.txt in the GTFS-Fares v2 spec.
class FareMedia {
  final String fareMediaId;

  /// Already translated when a translation exists. Falls back to the id,
  /// since fare_media_name is optional in the spec.
  final String name;

  final FareMediaType type;

  static const fareMediaIdKey = 'fare_media_id';
  static const fareMediaNameKey = 'fare_media_name';
  static const fareMediaTypeKey = 'fare_media_type';

  static const List<String> requiredFields = [
    fareMediaIdKey,
    fareMediaTypeKey,
  ];

  const FareMedia({
    required this.fareMediaId,
    required this.name,
    required this.type,
  });

  factory FareMedia.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedName,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final id = getValue(fareMediaIdKey);
    final rawName = getValue(fareMediaNameKey);
    final resolvedName = translatedName ?? rawName;

    return FareMedia(
      fareMediaId: id,
      name: resolvedName.isEmpty ? id : resolvedName,
      type: FareMediaType.fromGtfsValue(getValue(fareMediaTypeKey)),
    );
  }

  static bool hasRequiredHeaders(Map<String, int> headers) {
    for (final field in requiredFields) {
      if (!headers.containsKey(field)) return false;
    }
    return true;
  }

  static bool isValidRow(List<dynamic> row, Map<String, int> headers) {
    for (final field in requiredFields) {
      final index = headers[field]!;
      if (index >= row.length || row[index].toString().trim().isEmpty) {
        return false;
      }
    }

    // Ensure fare_media_type is a valid integer. Out-of-range values are
    // still accepted and mapped to FareMediaType.unknown.
    final typeStr = row[headers[fareMediaTypeKey]!].toString().trim();
    if (int.tryParse(typeStr) == null) {
      return false;
    }

    return true;
  }
}