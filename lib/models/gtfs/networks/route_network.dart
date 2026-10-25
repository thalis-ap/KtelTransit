/// Associates a route (from routes.txt) with a network (from networks.txt).
/// See route_networks.txt in the GTFS-Fares v2 spec.
///
/// Required companion of networks.txt: a network with no routes in this
/// file is defined but unusable. Its presence is "conditionally forbidden"
/// whenever routes.txt contains its own network_id column.
class RouteNetwork {
  /// Identifies a network from networks.txt. Required.
  final String networkId;

  /// Identifies a route from routes.txt. Required.
  final String routeId;

  static const networkIdKey = 'network_id';
  static const routeIdKey = 'route_id';

  static const List<String> requiredFields = [
    networkIdKey,
    routeIdKey,
  ];

  const RouteNetwork({
    required this.networkId,
    required this.routeId,
  });

  factory RouteNetwork.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices,
      ) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return RouteNetwork(
      networkId: getValue(networkIdKey),
      routeId: getValue(routeIdKey),
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
    return true;
  }
}