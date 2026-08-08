import 'package:latlong2/latlong.dart';

class Region {
  final String id;
  final String name;
  final LatLng center;
  // depends on how large the area is bigger area -> smaller zoom
  final double defaultZoom;

  const Region({
    required this.id,
    required this.name,
    required this.center,
    required this.defaultZoom,
  });
}

// To add a new region, simply add it in the following list - id is unique
const List<Region> availableRegions = [
  Region(
    id: 'lefkada',
    name: 'Λευκάδα',
    center: LatLng(38.718520, 20.654077),
    defaultZoom: 10.5,
  ),
  Region(
    id: 'kefalonia',
    name: 'Κεφαλονιά',
    center: LatLng(38.254425, 20.566609),
    defaultZoom: 10.0,
  ),
];