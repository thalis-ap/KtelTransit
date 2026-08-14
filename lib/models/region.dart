import 'package:latlong2/latlong.dart';

class Region {
  final String id;
  final String name, englishName;
  final LatLng center;
  // depends on how large the area is bigger area -> smaller zoom
  final double defaultZoom;

  const Region({
    required this.id,
    required this.name,
    required this.englishName,
    required this.center,
    required this.defaultZoom,
  });

  String getLocalizedName(String languageCode) {
    return languageCode == 'en' ? englishName : name;
  }
}

// To add a new region, simply add it in the following list - id is unique
const List<Region> availableRegions = [
  Region(
    id: 'lefkada',
    name: 'Λευκάδα',
    englishName: 'Lefkada',
    center: LatLng(38.718520, 20.654077),
    defaultZoom: 10.5,
  ),
  Region(
    id: 'kefalonia',
    name: 'Κεφαλονιά',
    englishName: 'Kefalonia',
    center: LatLng(38.254425, 20.566609),
    defaultZoom: 10.0,
  ),
];