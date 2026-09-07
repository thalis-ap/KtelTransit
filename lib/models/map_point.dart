import 'package:latlong2/latlong.dart';

class MapPoint {
  String name;
  final LatLng coordinates;

  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;
  
  MapPoint({required this.name, required this.coordinates});


  String getLatLngAsString() {
    return "${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°";
  }
}