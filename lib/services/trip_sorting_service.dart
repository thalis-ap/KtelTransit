import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/models/trip_sort_filter.dart';

class TripSortingService {
  static List<RoutingTrip> apply(
    List<RoutingTrip> trips,
    TripSortFilter filter,
    DateTime selectedDateTime,
  ) {
    // Filter first
    List<RoutingTrip> filtered = _filterTrips(trips, filter);

    // Then sort
    return _sortTrips(filtered, filter, selectedDateTime);
  }

  static List<RoutingTrip> _filterTrips(
    List<RoutingTrip> trips,
    TripSortFilter filter,
  ) {
    return trips.where((trip) {
      // If filter says no walking, exclude pure walking trips
      if (!filter.includeWalking && trip.busTrip == null) {
        return false;
      }

      // If filter says no direct, exclude trips with 0 transfers
      if (!filter.includeDirect && trip.busTrip?.isTransfer == false) {
        return false;
      }

      // If filter says no transfers, exclude trips with transfers
      if (!filter.includeTransfers && trip.busTrip?.isTransfer == true) {
        return false;
      }

      return true;
    }).toList();
  }

  static List<RoutingTrip> _sortTrips(
    List<RoutingTrip> trips,
    TripSortFilter filter,
    DateTime selectedDateTime,
  ) {
    // Always sort ascending and then reverse if filter.sortDirection is desceding
    switch (filter.sortBy) {
      case SortCriterion.totalDuration:
        trips.sort((a, b) => a.durationFull.compareTo(b.durationFull));
        break;
      case SortCriterion.tripDuration:
        trips.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case SortCriterion.departureTime:
        trips.sort(
          (a, b) => a
              .getDepartureDateTime(selectedDateTime)
              .compareTo(b.getDepartureDateTime(selectedDateTime)),
        );
        break;
      case SortCriterion.arrivalTime:
        trips.sort(
          (a, b) => a
              .getArrivalDateTime(selectedDateTime)
              .compareTo(b.getArrivalDateTime(selectedDateTime)),
        );
        break;
      case SortCriterion.cost:
        // TODO add the fare to the routing trip
        trips.sort((a, b) => -1);
        break;
      case SortCriterion.transferCount:
        trips.sort(
          (a, b) => (a.busTrip?.transferCount ?? 0).compareTo(
            (b.busTrip?.transferCount ?? 0),
          ),
        );
        break;
      case SortCriterion.walkingTime:
        trips.sort((a, b) => a.walkingDuration.compareTo(b.walkingDuration));
        break;
    }

    // Reverse the list if user selected descending
    final List<RoutingTrip> sorted = filter.sortDirection == SortDirection.ascending
        ? trips
        : trips.reversed.toList();

    return sorted;
  }
}
