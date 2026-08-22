import 'package:latlong2/latlong.dart';

/// This class is used for the actual osrm-computed trip and must not be
/// confused with the Trip class, which is a generic class to hold basic info
class BusTrip {
  /// Points and duration attributes are online based data. Keep them null
  /// until we retrieve them from OSRM. This is done because we are mixiing
  /// online with offline data (for example routeName can be fetched offline
  /// from the routes.txt file, while points list must be fetched through
  /// osrm)
  final List<LatLng>? points;

  // This is the duration computed using safe duration factor+offset
  // Note: It can be different from estimatedDuration
  final int? safeDuration; // in seconds2

  // Required locally fetched info
  final bool isTransfer, isStartAlsoOrigin;
  final String originStopName, destinationStopName;
  final DateTime originDepartureDateTime,
      startDepartureDateTime,
      destArrivalDateTime;
  
  
  // If the trip has a transfer then this is the first route name,
  // If not then its just the route name
  final String firstRouteName;
  
  // If the trip has a transfer trip then this is not null
  final String? secondRouteName;
  
  // This is the duration of the trip computed using the stop_times.txt local
  // file. It should not be confused with safeDuration which uses OSRM data.
  final int estimatedDuration; // in seconds

  // Transfer related - can be null
  final String? transferStopName;
  final DateTime? transferArrivalDateTime, transferDepartureDateTime;
  
  BusTrip({
    required this.isStartAlsoOrigin,
    required this.firstRouteName,
    required this.originStopName,
    required this.originDepartureDateTime,
    required this.destinationStopName,
    required this.startDepartureDateTime,
    required this.destArrivalDateTime,
    required this.isTransfer,
    required this.estimatedDuration,
    this.points,
    this.safeDuration,
    this.transferStopName,
    this.transferArrivalDateTime,
    this.transferDepartureDateTime,
    this.secondRouteName,
  });

  BusTrip copyWith({
    List<LatLng>? points,
    int? safeDuration,
    bool? isTransfer,
    bool? isStartAlsoOrigin,
    String? firstRouteName,
    String? originStopName,
    String? destinationStopName,
    DateTime? originDepartureDateTime,
    DateTime? startDepartureDateTime,
    DateTime? destArrivalDateTime,
    int? estimatedDuration,
    String? transferStopName,
    DateTime? transferArrivalDateTime,
    DateTime? transferDepartureDateTime,
    String? secondRouteName,
  }) {
    return BusTrip(
      points: points ?? this.points,
      safeDuration: safeDuration ?? this.safeDuration,
      isTransfer: isTransfer ?? this.isTransfer,
      isStartAlsoOrigin: isStartAlsoOrigin ?? this.isStartAlsoOrigin,
      firstRouteName: firstRouteName ?? this.firstRouteName,
      originStopName: originStopName ?? this.originStopName,
      destinationStopName: destinationStopName ?? this.destinationStopName,
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
      secondRouteName: secondRouteName ?? this.secondRouteName,
    );
  }
}
