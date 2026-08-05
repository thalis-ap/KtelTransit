/// This class contains the generic info of a trip and must not be confused
/// with the OsrmTrip class which represents and actual computed trip with
/// coords (points) and duration.
class Trip {
  final String routeId, serviceId, tripId, headsign;
  final int directionId;

  const Trip({required this.routeId, required this.serviceId, required this.tripId, required this.headsign, required this.directionId});

  factory Trip.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    return Trip(
      tripId: row[headerIndices['trip_id']!].toString(),
      routeId: row[headerIndices['route_id']!].toString(),
      serviceId: row[headerIndices['service_id']!].toString(),
      headsign: row[headerIndices['trip_headsign']!].toString(),
      directionId: int.parse(row[headerIndices['direction_id']!].toString()),
    );
  }

  /// Returns the correct route name depending on which is the start stop or
  /// in other words, which is the direction of the route
  String getDisplayName(String routeName) {
    return directionId == 1 ? routeName.split(' - ').reversed.join(' - ') : routeName;
  }

  String getShortDisplayName(String routeName) {
    List<String> parts = getDisplayName(routeName).split(' - ');
    return "${parts.first} - ${parts.last}";
  }

}