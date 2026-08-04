import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ktel_transit/models/osrm_trip.dart';
import 'package:latlong2/latlong.dart';

class OsrmService {

  /// Returns a complete OsrmTrip object, including the points and safeDuration
  /// attributes, once given a semi-complete OsrmTrip object and a start/dest
  /// pair of LatLng points. It safely returns a new OsrmTrip object using
  /// copyWith() function on the existing immutable object.
  static Future<OsrmTrip> getRoute(
    LatLng start,
    LatLng destination,
    OsrmTrip osrmTrip,
  ) async {
    // OSRM expects coordinates in Longitude,Latitude order
    final url =
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson&overview=full';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Navigate through the JSON response to find the coordinate array
      final List coordinates = data['routes'][0]['geometry']['coordinates'];

      // Get the car-driving duration so that we can calculate the safe duration
      final double carDuration = (data['routes'][0]['duration'] as num)
          .toDouble();

      // Returns a complete OsrmTrip object after adding the coordinates and
      // duration of the trip in minutes fetched from the OSRM API.
      return osrmTrip.copyWith(
        points: coordinates.map((coord) => LatLng(coord[1], coord[0])).toList(),
        // factor = 1.25, offset = 300s (5 minutes)
        safeDuration: ((1.25 * carDuration + 300) / 60).toInt(),
      );
    } else {
      throw Exception('Failed to fetch route from OSRM');
    }
  }
}
