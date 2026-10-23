import 'package:latlong2/latlong.dart';

class MapPoint {
  String name, subtitle;
  final LatLng coordinates;

  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;
  
  MapPoint({required this.name, this.subtitle = "", required this.coordinates});


  String getLatLngAsString() {
    return "${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°";
  }
}