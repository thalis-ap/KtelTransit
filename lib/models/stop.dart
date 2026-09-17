import 'package:latlong2/latlong.dart';
import 'map_point.dart';

class Stop extends MapPoint {
  final String stopId;

  static const stopIdKey = 'stop_id';
  static const stopNameKey = 'stop_name';
  static const stopLatKey = 'stop_lat';
  static const stopLonKey = 'stop_lon';

  static const List<String> requiredFields = [
    stopIdKey,
    stopNameKey,
    stopLatKey,
    stopLonKey,
  ];

  Stop({
    required this.stopId,
    required super.name,
    required super.coordinates,
  });

  factory Stop.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedName,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final stopId = getValue(stopIdKey);
    final rawName = getValue(stopNameKey);

    return Stop(
      stopId: stopId,
      name: translatedName ?? rawName,
      coordinates: LatLng(
        double.parse(getValue(stopLatKey)),
        double.parse(getValue(stopLonKey)),
      ),
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

    // Ensure coordinates are valid numbers to prevent double.parse crashes
    final latStr = row[headers[stopLatKey]!].toString().trim();
    final lonStr = row[headers[stopLonKey]!].toString().trim();
    if (double.tryParse(latStr) == null || double.tryParse(lonStr) == null) {
      return false;
    }

    return true;
  }
}