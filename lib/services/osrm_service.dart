import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:ktel_transit/models/walking_trip.dart';
import 'package:latlong2/latlong.dart';

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
  static Future<OsrmTrip> getRoute(
    LatLng start,
    LatLng destination,
    OsrmTrip osrmTrip,
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
      final double carDuration = (data['routes'][0]['duration'] as num)
          .toDouble();

      final List<LatLng> points = coordinates
          .map((coord) => LatLng(coord[1], coord[0]))
          .toList();
      // factor = 1.25, offset = 300s (5 minutes)
      final int safeDuration = ((1.25 * carDuration + 300) / 60).toInt();

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
        'https://router.project-osrm.org/route/v1/foot/'
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
