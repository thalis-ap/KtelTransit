import 'package:latlong2/latlong.dart';
import 'map_point.dart';

class Stop extends MapPoint {
  final String stopId;

  // Contains info about the stop (e.g. the surroundings, labels, ...)
  final String stopDesc;

  // Indicates if a point is accessible via a wheelchair. Null means unsure
  final bool? wheelchairBoarding;

  static const stopIdKey = 'stop_id';
  static const stopNameKey = 'stop_name';
  static const stopLatKey = 'stop_lat';
  static const stopLonKey = 'stop_lon';
  static const stopDescKey = 'stop_desc';
  static const wheelchairBoardingKey = 'wheelchair_boarding';

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
    this.stopDesc = "",
    this.wheelchairBoarding,
  });

  factory Stop.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedName,
        String? translatedDesc,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return Stop(
      stopId: getValue(stopIdKey),
      name: translatedName ?? getValue(stopNameKey),
      coordinates: LatLng(
        double.parse(getValue(stopLatKey)),
        double.parse(getValue(stopLonKey)),
      ),
      stopDesc: translatedDesc ?? getValue(stopDescKey),
      wheelchairBoarding: _getWheelchairBoardingValue(getValue(wheelchairBoardingKey))
    );
  }

  /// Transforms gtfs values of 0,1,2 to null, true, false respectively
  static bool? _getWheelchairBoardingValue(String gtfsValue) {
    switch (gtfsValue) {
      case '2':
        return false;
      case '1':
        return true;
      case '0':
      default:
        return null;
    }
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