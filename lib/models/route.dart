class Route {
  final String routeId, agencyId, shortName, longName;
  final int routeType;

  const Route({required this.routeId, required this.agencyId, required this.shortName, required this.longName, required this.routeType});

  factory Route.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    return Route(
      routeId: row[headerIndices['route_id']!].toString(),
      agencyId: row[headerIndices['agency_id']!].toString(),
      shortName: row[headerIndices['route_short_name']!].toString(),
      longName: row[headerIndices['route_long_name']!].toString(),
      routeType: int.parse(row[headerIndices['route_type']!].toString()),
    );
  }
}