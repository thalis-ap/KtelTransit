import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/models/bus_trip.dart';
import 'package:ktel_transit/models/walking_trip.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import 'package:ktel_transit/services/distance_service.dart';
import 'package:latlong2/latlong.dart';

import '../models/routing_trip.dart';
import '../models/stop.dart';

class _CachedBusRoute {
  final List<LatLng> points;
  final int safeDuration;

  _CachedBusRoute({required this.points, required this.safeDuration});
}

class BusService {
  static final Map<String, _CachedBusRoute> _cache = {};

  /// Returns a complete OsrmTrip object, including the points and safeDuration
  /// attributes, once given a semi-complete OsrmTrip object and a start/dest
  /// pair of LatLng points. It safely returns a new OsrmTrip object using
  /// copyWith() function on the existing immutable object.
  static Future<BusTrip> getRoute(
    LatLng start,
    LatLng destination,
    BusTrip osrmTrip,
  ) async {
    // Cache key is of the form start latlng | dest latlng
    final String cacheKey =
        '${start.latitude},${start.longitude}|${destination.latitude},${destination.longitude}';

    // If we already calculated the path between these two stops, inject the cached data!
    if (_cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey]!;
      return osrmTrip.copyWith(
        points: cachedData.points,
        safeDuration: cachedData.safeDuration,
      );
    }
    // OSRM expects coordinates in Longitude,Latitude order
    final String url =
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson&overview=full';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Service not available: ${response.statusCode}");
      }

      final data = json.decode(response.body);

      // Navigate through the JSON response to find the coordinate array
      final List coordinates = data['routes'][0]['geometry']['coordinates'];

      // Get the car-driving duration so that we can calculate the safe duration
      final int carDuration = (data['routes'][0]['duration'] as num).toInt();

      final List<LatLng> points = coordinates
          .map((coord) => LatLng(coord[1], coord[0]))
          .toList();
      // factor = 1.25, offset = 300s (5 minutes)
      final int safeDuration = (1.25 * carDuration).toInt() + 300;

      // Save the calculated geographic data to the cache
      _cache[cacheKey] = _CachedBusRoute(
        points: points,
        safeDuration: safeDuration,
      );

      // Returns a complete OsrmTrip object after adding the coordinates and
      // duration of the trip in minutes fetched from the OSRM API.
      return osrmTrip.copyWith(points: points, safeDuration: safeDuration);
    } catch (e) {
      throw Exception("Error fetching route $e");
    }
  }
}

class WalkingService {
  /// Cache some results so as not to spam the OSRM service. The key of the
  /// cache map is of the form start latlng | dest latlng
  static final Map<String, WalkingTrip> _cache = {};

  /// Returns a WalkingTrip object, that represents a path from start to
  /// destination. Upon any error, null is returned.
  static Future<WalkingTrip?> getRoute(LatLng start, LatLng destination) async {
    final String cacheKey =
        '${start.latitude},${start.longitude}|${destination.latitude},${destination.longitude}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final String url =
        'https://routing.openstreetmap.de/routed-foot/route/v1/foot/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['routes'] == null || data['routes'].isEmpty) return null;
      final routeData = data['routes'][0];

      final double distance = routeData['distance'].toDouble();
      final double duration = routeData['duration'].toDouble();

      final List<dynamic> coordinates = routeData['geometry']['coordinates'];
      final List<LatLng> points = coordinates.map((coord) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();

      final newRoute = WalkingTrip(
        distance: distance,
        duration: duration,
        points: points,
      );

      _cache[cacheKey] = newRoute;

      return newRoute;
    } catch (_) {
      return null;
    }
  }
}

/// This class acts as a multimodal (walk/bus) routing service and can handle
/// all type of requests
class RoutingService {
  // Initialize once
  static final GtfsRepository repository = GtfsRepository();

  // Caps to ensure we don't bombard the ui with huge amount of trips
  static const int _maxNearestStops = 3;
  static const int _maxTripsPerCombo =
      10; // cap bus trips considered per stop-pair
  static const int _maxFinalResults = 20; // cap what we ever return to the UI

  static Future<List<RoutingTrip>> getStopToStopRoutes(
    Stop start,
    Stop destination,
    DateTime selectedTime,
  ) async {
    final List<BusTrip> trips = repository.findAllTripsBetween(
      start.stopId,
      destination.stopId,
      selectedTime: selectedTime,
    );

    List<RoutingTrip> finalTrips = trips
        .map(
          (busTrip) => RoutingTrip(
            startPoint: start,
            destinationPoint: destination,
            busTrip: busTrip,
          ),
        )
        .toList();

    finalTrips.sort((a, b) {
      int res = a
          .getArrivalDateTime(selectedTime)
          .compareTo(b.getArrivalDateTime(selectedTime));
      if (res == 0) {
        return (a.durationFull).compareTo((b.durationFull));
      }

      return res;
    });

    // Always add a walking trip
    final WalkingTrip? walkingTrip = await WalkingService.getRoute(
      start.coordinates,
      destination.coordinates,
    );

    // Insert the (non null) walking trip in the first position. Its arrival
    // time will (probably) be less that the busses'. Either way, user should
    // see it first since the other busses' trips depart on another day
    if (walkingTrip != null) {
      finalTrips.insert(
        0,
        RoutingTrip(
          startPoint: start,
          destinationPoint: destination,
          accessTrip: walkingTrip,
        ),
      );
    }

    return finalTrips;
  }

  static Future<List<RoutingTrip>> getPinToStopRoutes(
    MapPoint start,
    Stop destination,
    DateTime selectedTime,
  ) async {
    // Find the nearest stops to the start pin (SLD)
    List<MapEntry<Stop, double>> nearestStopsToStart =
        DistanceService.findNearestStops(
          start.coordinates,
          repository.stops,
          limit: _maxNearestStops,
        );

    // Kick off the pure-walking option to the destination stop
    final WalkingTrip? pureWalkingTrip = await WalkingService.getRoute(
      start.coordinates,
      destination.coordinates,
    );

    if (pureWalkingTrip != null && nearestStopsToStart.isNotEmpty) {
      // Find the shortest stop distance (SLD)
      final double shortestSLD = nearestStopsToStart.first.value;

      // Get a rough estimate of the duration needed to get there
      final double estimatedWalkToNearestStop =
          WalkingTrip.getDurationFromDistance(shortestSLD);

      // If walking to the nearest stop already takes longer than pure walking,
      // no bus trip can be faster (bus adds extra time on top of that walk).
      if (estimatedWalkToNearestStop >= pureWalkingTrip.duration) {
        return [
          RoutingTrip(
            startPoint: start,
            destinationPoint: destination,
            accessTrip: pureWalkingTrip,
          ),
        ];
      }
    }

    // Fetch all access-walk legs concurrently instead of one at a time
    final busFuture = Future.wait(
      nearestStopsToStart.map((entry) async {
        final WalkingTrip? accessTrip = await WalkingService.getRoute(
          start.coordinates,
          entry.key.coordinates,
        );
        // Continue with the next bus stop if we can't find a way (walking)
        if (accessTrip == null) return <RoutingTrip>[];

        // Add the time needed to walk to the start stop
        final DateTime adjustedTime = selectedTime.add(
          Duration(seconds: accessTrip.duration.toInt()),
        );

        final List<BusTrip> busTrips = repository
            .findAllTripsBetween(
              entry.key.stopId,
              destination.stopId,
              selectedTime: adjustedTime,
            )
            .take(_maxTripsPerCombo)
            .toList();

        return busTrips
            .map(
              (busTrip) => RoutingTrip(
                startPoint: start,
                destinationPoint: destination,
                accessTrip: accessTrip,
                busTrip: busTrip,
              ),
            )
            .toList();
      }),
    );

    final List<RoutingTrip> busResults = (await busFuture)
        .expand((e) => e)
        .toList();

    List<RoutingTrip> finalTrips = [];
    if (pureWalkingTrip != null) {
      // Add the walking trip always
      finalTrips.add(
        RoutingTrip(
          startPoint: start,
          destinationPoint: destination,
          accessTrip: pureWalkingTrip,
        ),
      );

      // Only add bus results (ones with buses invloved) whose access time
      // to the start stop is less than the pure walk time. We don't use
      // (accessDuration + busDuration < pureWalkDuration) because the user
      // might prefer to walk less
      for (RoutingTrip trip in busResults) {
        if (trip.accessDuration < pureWalkingTrip.duration) {
          finalTrips.add(trip);
        }
      }
    } else {
      // No walking trip found - add all bus results
      finalTrips.addAll(busResults);
    }

    finalTrips.sort((a, b) {
      int res = a
          .getArrivalDateTime(selectedTime)
          .compareTo(b.getArrivalDateTime(selectedTime));
      if (res == 0) {
        return a.durationFull.compareTo(b.durationFull);
      }

      return res;
    });

    return finalTrips.take(_maxFinalResults).toList();
  }

  static Future<List<RoutingTrip>> getStopToPinRoutes(
    Stop start,
    MapPoint destination,
    DateTime selectedTime,
  ) async {
    // Find the nearest stops to the destination pin (SLD)
    List<MapEntry<Stop, double>> nearestStopsToDestination =
        DistanceService.findNearestStops(
          destination.coordinates,
          repository.stops,
          limit: _maxNearestStops,
        );

    // Kick off the pure-walking option from the start stop to the destination pin
    final WalkingTrip? pureWalkingTrip = await WalkingService.getRoute(
      start.coordinates,
      destination.coordinates,
    );

    if (pureWalkingTrip != null && nearestStopsToDestination.isNotEmpty) {
      final double shortestSLD = nearestStopsToDestination.first.value;
      final double estimatedWalkFromNearestStop =
          WalkingTrip.getDurationFromDistance(shortestSLD);

      // If walking from the nearest stop to the pin already takes longer than pure walking,
      // no bus trip can be faster (bus adds extra time on top of that walk).
      if (estimatedWalkFromNearestStop >= pureWalkingTrip.duration) {
        return [
          RoutingTrip(
            startPoint: start,
            destinationPoint: destination,
            accessTrip: pureWalkingTrip,
          ),
        ];
      }
    }

    // Fetch all egress-walk legs concurrently, while also fetching bus trips in parallel
    final busFuture = Future.wait(
      nearestStopsToDestination.map((entry) async {
        // Bus search doesn't depend on the egress walk, so run it concurrently
        final busTripsFuture = Future(
          () => repository
              .findAllTripsBetween(
                start.stopId,
                entry.key.stopId,
                selectedTime: selectedTime,
              )
              .take(_maxTripsPerCombo)
              .toList(),
        );

        final egressTripFuture = WalkingService.getRoute(
          entry.key.coordinates,
          destination.coordinates,
        );

        final results = await Future.wait([busTripsFuture, egressTripFuture]);
        final List<BusTrip> busTrips = results[0] as List<BusTrip>;
        final WalkingTrip? egressTrip = results[1] as WalkingTrip?;

        if (egressTrip == null || busTrips.isEmpty) return <RoutingTrip>[];

        return busTrips
            .map(
              (busTrip) => RoutingTrip(
                startPoint: start,
                destinationPoint: destination,
                busTrip: busTrip,
                egressTrip: egressTrip,
              ),
            )
            .toList();
      }),
    );

    final List<RoutingTrip> busResults = (await busFuture)
        .expand((e) => e)
        .toList();

    List<RoutingTrip> finalTrips = [];
    if (pureWalkingTrip != null) {
      finalTrips.add(
        RoutingTrip(
          startPoint: start,
          destinationPoint: destination,
          accessTrip: pureWalkingTrip,
        ),
      );

      // Only add bus results whose egress walk is shorter than the pure walk
      for (RoutingTrip trip in busResults) {
        if (trip.egressDuration < pureWalkingTrip.duration) {
          finalTrips.add(trip);
        }
      }
    } else {
      finalTrips.addAll(busResults);
    }

    finalTrips.sort((a, b) {
      int res = a
          .getArrivalDateTime(selectedTime)
          .compareTo(b.getArrivalDateTime(selectedTime));
      if (res == 0) {
        return a.durationFull.compareTo(b.durationFull);
      }

      return res;
    });

    return finalTrips.take(_maxFinalResults).toList();
  }

  static Future<List<RoutingTrip>> getPinToPinRoutes(
    MapPoint start,
    MapPoint destination,
    DateTime selectedTime,
  ) async {
    // Find nearest stops to both pins (SLD)
    List<MapEntry<Stop, double>> nearestStopsToStart =
        DistanceService.findNearestStops(
          start.coordinates,
          repository.stops,
          limit: _maxNearestStops,
        );

    List<MapEntry<Stop, double>> nearestStopsToDestination =
        DistanceService.findNearestStops(
          destination.coordinates,
          repository.stops,
          limit: _maxNearestStops,
        );

    // Kick off the pure-walking option from the start to the destination pin
    final WalkingTrip? pureWalkingTrip = await WalkingService.getRoute(
      start.coordinates,
      destination.coordinates,
    );

    if (pureWalkingTrip != null &&
        nearestStopsToStart.isNotEmpty &&
        nearestStopsToDestination.isNotEmpty) {
      final double minAccessSLD = nearestStopsToStart.first.value;
      final double minEgressSLD = nearestStopsToDestination.first.value;
      final double estimatedTotalWalkToStartStop =
          WalkingTrip.getDurationFromDistance(minAccessSLD);
      final double estimatedTotalWalkToDestStop =
          WalkingTrip.getDurationFromDistance(minEgressSLD);

      // If the access + egress walk time exceeds the total walk time of a trip
      // there is no reason to keep searching for buses, pure walk trip
      // takes less time anyway
      if (estimatedTotalWalkToStartStop + estimatedTotalWalkToDestStop >= pureWalkingTrip.duration) {
        return [
          RoutingTrip(
            startPoint: start,
            destinationPoint: destination,
            accessTrip: pureWalkingTrip,
          ),
        ];
      }
    }

    // Fetch all combinations of access + egress walks concurrently
    final busFuture = Future.wait(
      nearestStopsToStart.map((startEntry) async {
        final WalkingTrip? accessTrip = await WalkingService.getRoute(
          start.coordinates,
          startEntry.key.coordinates,
        );
        if (accessTrip == null) return <RoutingTrip>[];

        final DateTime adjustedTime = selectedTime.add(
          Duration(seconds: accessTrip.duration.toInt()),
        );

        // For each destination stop, fetch bus trips and egress walk in parallel
        final innerResults = await Future.wait(
          nearestStopsToDestination.map((destEntry) async {
            final List<BusTrip> busTrips = repository
                .findAllTripsBetween(
                  startEntry.key.stopId,
                  destEntry.key.stopId,
                  selectedTime: adjustedTime,
                )
                .take(_maxTripsPerCombo)
                .toList();

            if (busTrips.isEmpty) return <RoutingTrip>[];

            final WalkingTrip? egressTrip = await WalkingService.getRoute(
              destEntry.key.coordinates,
              destination.coordinates,
            );
            if (egressTrip == null) return <RoutingTrip>[];

            return busTrips
                .map(
                  (busTrip) => RoutingTrip(
                    startPoint: start,
                    destinationPoint: destination,
                    accessTrip: accessTrip,
                    busTrip: busTrip,
                    egressTrip: egressTrip,
                  ),
                )
                .toList();
          }),
        );

        return innerResults.expand((e) => e).toList();
      }),
    );

    final List<RoutingTrip> busResults = (await busFuture)
        .expand((e) => e)
        .toList();

    List<RoutingTrip> finalTrips = [];
    if (pureWalkingTrip != null) {
      finalTrips.add(
        RoutingTrip(
          startPoint: start,
          destinationPoint: destination,
          accessTrip: pureWalkingTrip,
        ),
      );

      // Keep only the results whose total walk duration (access + egress) is
      // less than the pure walking duration
      for (RoutingTrip trip in busResults) {
        if (trip.accessDuration + trip.egressDuration < pureWalkingTrip.duration) {
          finalTrips.add(trip);
        }
      }
    } else {
      finalTrips.addAll(busResults);
    }

    finalTrips.sort((a, b) {
      int res = a
          .getArrivalDateTime(selectedTime)
          .compareTo(b.getArrivalDateTime(selectedTime));
      if (res == 0) {
        return a.durationFull.compareTo(b.durationFull);
      }

      return res;
    });

    return finalTrips.take(_maxFinalResults).toList();
  }

  static Future<List<RoutingTrip>> getRoutes(
    MapPoint start,
    MapPoint destination,
    DateTime selectedTime,
  ) async {
    if (start is Stop && destination is Stop) {
      // Both are stops, need only BusService
      return await getStopToStopRoutes(start, destination, selectedTime);
    } else if (start is! Stop && destination is Stop) {
      // Start is not a stop, destination is a stop
      return await getPinToStopRoutes(start, destination, selectedTime);
    } else if (start is Stop && destination is! Stop) {
      // Start is a stop, destination is not
      return await getStopToPinRoutes(start, destination, selectedTime);
    } else {
      // Neither start nor destination is a stop
      return await getPinToPinRoutes(start, destination, selectedTime);
    }
  }
}
