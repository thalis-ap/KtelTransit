import 'package:latlong2/latlong.dart';

import 'map_point.dart';

class Stop extends MapPoint {
  final String stopId;

  Stop({required this.stopId, required super.name, required super.coordinates});

  factory Stop.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    final String stopName = row[headerIndices['stop_name']!].toString();
    return Stop(
      stopId: row[headerIndices['stop_id']!].toString(),
      name: stopName,
      coordinates: LatLng(
        double.parse(row[headerIndices['stop_lat']!].toString()),
        double.parse(row[headerIndices['stop_lon']!].toString()),
      ),
    );
  }
}
