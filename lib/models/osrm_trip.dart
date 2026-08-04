import 'package:latlong2/latlong.dart';

/// This class is used for the actual osrm-computed trip and must not be
/// confused with the Trip class, which is a generic class to hold basic info
/// It represents a single trip from one source to one destination and
/// cannot be used for trips with line changes (transfers)
class OsrmTrip {
  /// Points and duration attributes are online based data. Keep them null
  /// until we retrieve them from OSRM. This is done because we are mixiing
  /// online with offline data (for example routeName can be fetched offline
  /// from the routes.txt file, while points list must be fetched through
  /// osrm)
  final List<LatLng>? points;

  // This is the duration computed using safe duration factor+offset
  // Note: It can be different from estimatedDuration
  final int? safeDuration;

  // Required locally fetched info
  final bool isTransfer, isStartAlsoOrigin;
  final String routeName, originStopName;
  final DateTime originDepartureDateTime,
      startDepartureDateTime,
      destArrivalDateTime;

  // This is the duration of the trip computed using the stop_times.txt local
  // file. It should not be confused with safeDuration which uses OSRM data.
  final int estimatedDuration;

  // Transfer related - can be null
  final String? transferStopName;
  final DateTime? transferArrivalDateTime, transferDepartureDateTime;

  OsrmTrip({
    required this.isStartAlsoOrigin,
    required this.routeName,
    required this.originStopName,
    required this.originDepartureDateTime,
    required this.startDepartureDateTime,
    required this.destArrivalDateTime,
    required this.isTransfer,
    required this.estimatedDuration,
    this.points,
    this.safeDuration,
    this.transferStopName,
    this.transferArrivalDateTime,
    this.transferDepartureDateTime,
  });

  OsrmTrip copyWith({
    List<LatLng>? points,
    int? safeDuration,
    bool? isTransfer,
    bool? isStartAlsoOrigin,
    String? routeName,
    String? originStopName,
    DateTime? originDepartureDateTime,
    DateTime? startDepartureDateTime,
    DateTime? destArrivalDateTime,
    int? estimatedDuration,
    String? transferStopName,
    DateTime? transferArrivalDateTime,
  }) {
    return OsrmTrip(
      points: points ?? this.points,
      safeDuration: safeDuration ?? this.safeDuration,
      isTransfer: isTransfer ?? this.isTransfer,
      isStartAlsoOrigin: isStartAlsoOrigin ?? this.isStartAlsoOrigin,
      routeName: routeName ?? this.routeName,
      originStopName: originStopName ?? this.originStopName,
      originDepartureDateTime:
          originDepartureDateTime ?? this.originDepartureDateTime,
      startDepartureDateTime:
          startDepartureDateTime ?? this.startDepartureDateTime,
      destArrivalDateTime: destArrivalDateTime ?? this.destArrivalDateTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      transferStopName: transferStopName ?? this.transferStopName,
      transferArrivalDateTime:
          transferArrivalDateTime ?? this.transferArrivalDateTime,
      transferDepartureDateTime:
          transferDepartureDateTime ?? this.transferDepartureDateTime,
    );
  }
}
