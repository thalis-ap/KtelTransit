import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static Future<String?> getPlaceName(LatLng coordinates, String languageCode) async {
    // We pass the coordinates and tell the API to return the name in the user's active language
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=18&addressdetails=1&accept-language=$languageCode');

    try {
      final request = await HttpClient().getUrl(url);

      // Nominatim requires a User-Agent header for their free API, otherwise they block the request
      request.headers.add('User-Agent', 'ktel_transit_app');

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);

        // Try to get the specific name of the place (e.g. "Kathisma Beach")
        final String? specificName = data['name'];
        if (specificName != null && specificName.isNotEmpty) {
          return specificName;
        }

        // Fallback: If it's just a random spot on a road, get the road or area name
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          return address['amenity'] ??
              address['leisure'] ??
              address['tourism'] ??
              address['road'] ??
              address['village'] ??
              address['town'] ??
              address['city'];
        }
      }
    } catch (_) {
      // If there's no internet or the API fails, it will gracefully return null
    }

    return null;
  }
}