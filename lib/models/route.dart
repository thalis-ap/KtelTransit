class Route {
  final String routeId, agencyId, shortName, longName;
  final int routeType;

  final String englishShortName, englishLongName;

  const Route({
    required this.routeId,
    required this.agencyId,
    required this.shortName,
    required this.longName,
    required this.routeType,
    required this.englishShortName,
    required this.englishLongName,
  });

  // Helper method for the short name
  String getLocalizedShortName(String languageCode) {
    return languageCode == 'en' ? englishShortName : shortName;
  }

  // Helper method for the long name
  String getLocalizedLongName(String languageCode) {
    return languageCode == 'en' ? englishLongName : longName;
  }

  factory Route.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? englishShortName,
        String? englishLongName,
      }) {
    final String shortName = row[headerIndices['route_short_name']!].toString();
    final String longName = row[headerIndices['route_long_name']!].toString();
    return Route(
      routeId: row[headerIndices['route_id']!].toString(),
      agencyId: row[headerIndices['agency_id']!].toString(),
      shortName: shortName,
      longName: longName,
      routeType: int.parse(row[headerIndices['route_type']!].toString()),
      englishShortName: englishShortName ?? shortName,
      englishLongName: englishLongName ?? longName,
    );
  }
}