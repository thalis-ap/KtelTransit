import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/utilities/time_format.dart';

/// Holds trips grouped by their departure status.
class TripGroups {
  /// Trips that depart on the same date as the user's selected time.
  final List<RoutingTrip> todayTrips;

  /// Trips that depart on the first available future date (only populated if
  /// there are no [todayTrips]).
  final List<RoutingTrip> nextTrips;

  /// Trips that have already departed (only applies to trips with a bus
  /// component).
  final List<RoutingTrip> pastTrips;

  const TripGroups({
    required this.todayTrips,
    required this.nextTrips,
    required this.pastTrips,
  });

  /// Returns true if there is at least one trip in any category.
  bool get hasAnyTrips =>
      todayTrips.isNotEmpty || nextTrips.isNotEmpty || pastTrips.isNotEmpty;

  // Returns true if there is at least one bus trip in any category
  bool get hasAnyBusTrips =>
      _hasAnyBusTrips(todayTrips) ||
      _hasAnyBusTrips(nextTrips) ||
      _hasAnyBusTrips(pastTrips);

  bool _hasAnyBusTrips(List<RoutingTrip> trips) {
    return trips.any((t) => t.busTrip != null);
  }
}

/// A pure logic service for grouping a list of trips.
class TripGroupingService {
  /// Groups the given [trips] into past, today, and next groups.
  ///
  /// [selectedTime] is the user-chosen departure time.
  /// [now] is the current moment (usually `DateTime.now()`).
  static TripGroups filterAndGroupTrips(
    List<RoutingTrip> trips,
    DateTime selectedTime,
    DateTime now,
  ) {
    // Step 1: Split the list into "past" and "active" trips.
    final (pastTrips, activeTrips) = _splitPastAndActive(trips, now);

    // Step 2: From active trips, filter those that depart on the selected date.
    final todayTrips = _getTodayTrips(activeTrips, selectedTime);

    bool hasAnyBusTripsToday = todayTrips.any((t) => t.busTrip != null);

    // Step 3: If there are no today trips, find the next available day's trips.
    final nextTrips = hasAnyBusTripsToday
        ? <RoutingTrip>[]
        : _getNextAvailableTrips(activeTrips, selectedTime, now);

    return TripGroups(
      todayTrips: todayTrips,
      nextTrips: nextTrips,
      pastTrips: pastTrips,
    );
  }

  /// Splits trips into past (departed) and active (not yet departed).
  /// A trip is considered past only if it has a transit trip (bus) and its
  /// departure time is before [now]. Pure walking trips are never "past".
  static (List<RoutingTrip>, List<RoutingTrip>) _splitPastAndActive(
    List<RoutingTrip> trips,
    DateTime now,
  ) {
    final past = <RoutingTrip>[];
    final active = <RoutingTrip>[];

    for (final trip in trips) {
      // A trip is past if:
      // 1. It has a bus component (transitTrip != null)
      // 2. Its calculated departure time is BEFORE the current time (now)
      if (trip.busTrip != null &&
          trip.getDepartureDateTime(now).compareTo(now) < 0) {
        past.add(trip);
      } else {
        active.add(trip);
      }
    }

    return (past, active);
  }

  /// Returns trips that depart on the same date as [selectedTime].
  static List<RoutingTrip> _getTodayTrips(
    List<RoutingTrip> activeTrips,
    DateTime selectedTime,
  ) {
    final selectedDateOnly = TimeFormat.dateTimeToDateOnly(selectedTime);

    return activeTrips.where((trip) {
      final tripDepartureDate = TimeFormat.dateTimeToDateOnly(
        trip.getDepartureDateTime(selectedTime),
      );
      return tripDepartureDate.compareTo(selectedDateOnly) == 0;
    }).toList();
  }

  /// Finds the first future day (after [now]) that has bus trips, and returns
  /// all active trips for that day.
  ///
  /// Uses [selectedTime] only to compute the departure date of each trip (the
  /// actual time-of-day is derived from the trip's schedule, not from
  /// [selectedTime]).
  static List<RoutingTrip> _getNextAvailableTrips(
    List<RoutingTrip> activeTrips,
    DateTime selectedTime,
    DateTime now,
  ) {
    // First, filter active trips to those that:
    // - Have a bus component (transitTrip != null)
    // - Depart strictly after 'now'
    final futureBusTrips = activeTrips.where((trip) {
      return trip.busTrip != null &&
          trip.getDepartureDateTime(now).compareTo(now) > 0;
    }).toList();

    if (futureBusTrips.isEmpty) {
      return [];
    }

    // Find the earliest departure date among these future bus trips.
    // We use selectedTime as a base because getDepartureDateTime uses it to
    // construct the DateTime (it adds the trip's schedule time to the date).
    DateTime earliestDate = futureBusTrips.first.getDepartureDateTime(
      selectedTime,
    );
    for (final trip in futureBusTrips) {
      final departure = trip.getDepartureDateTime(selectedTime);
      if (departure.compareTo(earliestDate) < 0) {
        earliestDate = departure;
      }
    }

    // Normalize to date-only for comparison.
    final earliestDateOnly = TimeFormat.dateTimeToDateOnly(earliestDate);

    // Return all trips that depart on that earliest date.
    return futureBusTrips.where((trip) {
      final departure = trip.getDepartureDateTime(selectedTime);
      return TimeFormat.dateTimeToDateOnly(
            departure,
          ).compareTo(earliestDateOnly) ==
          0;
    }).toList();
  }
}
