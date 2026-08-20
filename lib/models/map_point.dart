import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class MapPoint {
  String? name;
  final LatLng coordinates;

  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;
  
  MapPoint({required this.coordinates, this.name});

  String getLocalizedName(AppLocalizations l10n) {
    return name ?? l10n.chosenPoint;
  }
}