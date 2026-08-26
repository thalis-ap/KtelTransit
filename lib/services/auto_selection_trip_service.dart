import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/services/settings_service.dart';

/// This class acts as a selector for the best trip given a list of trips
/// It returns results based on the given preference for what's considered
/// 'best' trip
class AutoSelector {
  final List<RoutingTrip> trips;
  final DateTime selectedDateTime;

  // This is the id of the selection option, for example
  // AutoSelectBestRouteOption.minTotalTimeId
  final String optionId;

  // Will ignore pure walking trips even if they are the best ones
  final bool ignorePureWalk;

  AutoSelector({
    required this.trips,
    required this.selectedDateTime,
    required this.optionId,
    this.ignorePureWalk = false,
  });

  int getBestTripIndex() {
    switch (optionId) {
      case AutoSelectBestRouteOption.minTotalTimeId:
        return getLeastTotalTime();
      case AutoSelectBestRouteOption.minArrivalTimeId:
        return getEarliestArrivalTime();
      case AutoSelectBestRouteOption.minDepartTimeId:
        return getEarliestDepartureTime();
      default:
        // return invalid index in case the id is invalid
        return -1;
    }
  }

  /// Returns the index of the trip with the least total time
  int getLeastTotalTime() {
    int index = 0;
    double min = trips[0].duration;
    for (int i=1; i<trips.length; i++) {
      // Ignore pure walking trips, if filter is on
      if (ignorePureWalk && trips[i].busTrip == null) continue;

      if (trips[i].duration < min) {
        min = trips[i].duration;
        index = i;
      }
    }
    return index;
  }

  int getEarliestArrivalTime() {
    int index = 0;
    DateTime min = trips[0].getArrivalDateTime(selectedDateTime);
    for (int i=1; i<trips.length; i++) {
      // Ignore pure walking trips, if filter is on
      if (ignorePureWalk && trips[i].busTrip == null) continue;

      final DateTime currentArrival = trips[i].getArrivalDateTime(selectedDateTime);

      if (currentArrival.compareTo(min) < 0) {
        min = currentArrival;
        index = i;
      }
    }
    return index;
  }

  int getEarliestDepartureTime() {
    int index = 0;
    DateTime min = trips[0].getDepartureDateTime(selectedDateTime);
    for (int i=1; i<trips.length; i++) {
      // Ignore pure walking trips, if filter is on
      if (ignorePureWalk && trips[i].busTrip == null) continue;

      final DateTime currentArrival = trips[i].getDepartureDateTime(selectedDateTime);

      if (currentArrival.compareTo(min) < 0) {
        min = currentArrival;
        index = i;
      }
    }
    return index;
  }
}
