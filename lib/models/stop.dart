import 'package:latlong2/latlong.dart';

import 'map_point.dart';

class Stop extends MapPoint {
  final String stopId;
  final String englishName;

  Stop({
    required this.stopId,
    required this.englishName,
    required super.name,
    required super.coordinates,
  });

  String getLocalizedNameByLangCode(String languageCode) {
    // In stops, the name is always not null so name! is safe
    return languageCode == 'en' ? englishName : name!;
  }

  factory Stop.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? englishName,
      }) {
    final String stopName = row[headerIndices['stop_name']!].toString();
    return Stop(
      stopId: row[headerIndices['stop_id']!].toString(),
      name: stopName,
      coordinates: LatLng(double.parse(row[headerIndices['stop_lat']!].toString()), double.parse(row[headerIndices['stop_lon']!].toString())),
      englishName: englishName ?? stopName,
    );
  }
}