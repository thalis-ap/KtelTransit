import 'package:ktel_transit/models/stop.dart';

/// This class contains the generic info of a trip and must not be confused
/// with the RoutingTrip class which represents and actual computed trip with
/// coords (points) and duration.
class Trip {
  static const tripIdKey = 'trip_id';
  static const routeIdKey = 'route_id';
  static const serviceIdKey = 'service_id';
  static const headsignKey = 'trip_headsign';
  static const directionIdKey = 'direction_id';
  static const wheelchairBoardingKey = 'wheelchair_accessible';
  static const shapeIdKey = 'shape_id';

  static const List<String> requiredFields = [
    tripIdKey,
    routeIdKey,
    serviceIdKey,
    directionIdKey,
    // shapeIdKey,
  ];

  final String tripId;
  final String routeId;
  final String serviceId;
  final String headsign;
  final int directionId;
  final String shapeId;

  // Indicates if a specific trip can host wheelchair passengers, regardless
  // of the stop they are boarding on. For example if a trip does not have
  // wheelchair access but a stop has, then we should not show that it is
  // available.
  final WheelchairBoarding wheelchairBoarding;

  const Trip({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    required this.headsign,
    required this.directionId,
    required this.shapeId,
    this.wheelchairBoarding = WheelchairBoarding.unknown,
  });

  factory Trip.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return Trip(
      tripId: getValue(tripIdKey),
      routeId: getValue(routeIdKey),
      serviceId: getValue(serviceIdKey),
      headsign: getValue(headsignKey),
      directionId: int.parse(getValue(directionIdKey)),
      wheelchairBoarding: Stop.getWheelchairBoardingValue(
        getValue(wheelchairBoardingKey),
      ),
      shapeId: getValue(shapeIdKey),
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

    // Ensure direction_id is a valid integer
    final dirStr = row[headers[directionIdKey]!].toString().trim();
    if (int.tryParse(dirStr) == null) {
      return false;
    }

    return true;
  }

  /// Returns the correct route name depending on which is the start stop or
  /// in other words, which is the direction of the route
  String getDisplayName(String routeName) {
    return directionId == 1
        ? routeName.split(' - ').reversed.join(' - ')
        : routeName;
  }

  String getShortDisplayName(String routeName) {
    List<String> parts = getDisplayName(routeName).split(' - ');
    return "${parts.first} - ${parts.last}";
  }
}
