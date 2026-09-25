import '../utilities/number_utils.dart';

class Route {
  final String routeId, agencyId, shortName, longName;
  final int routeType;
  final int routeSortOrder;

  final String? routeColor;
  final String routeDesc;

  static const routeIdKey = 'route_id';
  static const agencyIdKey = 'agency_id';
  static const shortNameKey = 'route_short_name';
  static const longNameKey = 'route_long_name';
  static const routeTypeKey = 'route_type';
  static const routeColorKey = 'route_color';
  static const routeSortOrderKey = 'route_sort_order';
  static const routeDescKey = 'route_desc';

  static const List<String> requiredFields = [
    routeIdKey,
    agencyIdKey,
    shortNameKey,
    longNameKey,
    routeTypeKey,
  ];

  const Route({
    required this.routeId,
    required this.agencyId,
    required this.shortName,
    required this.longName,
    required this.routeType,
    this.routeColor,
    this.routeSortOrder = NumberUtils.maxInt,
    this.routeDesc = "",
  });

  factory Route.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedShortName,
        String? translatedLongName,
        String? translatedDesc,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final rawShortName = getValue(shortNameKey);
    final rawLongName = getValue(longNameKey);
    final color = getValue(routeColorKey);

    return Route(
      routeId: getValue(routeIdKey),
      agencyId: getValue(agencyIdKey), // Optional, won't crash if missing
      shortName: translatedShortName ?? rawShortName,
      longName: translatedLongName ?? rawLongName,
      routeType: int.parse(getValue(routeTypeKey)),
      routeColor: color.isEmpty ? null : color, // leave empty if no color was found
      routeSortOrder: int.tryParse(getValue(routeSortOrderKey)) ?? NumberUtils.maxInt,
      routeDesc: translatedDesc ?? getValue(routeDescKey),
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

    // Ensure route_type is a valid integer to prevent int.parse crashes
    final typeStr = row[headers[routeTypeKey]!].toString().trim();
    if (int.tryParse(typeStr) == null) {
      return false;
    }

    return true;
  }
}