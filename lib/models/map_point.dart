import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/stop.dart';
import 'package:latlong2/latlong.dart';

class MapPoint {
  String? name;
  final LatLng coordinates;

  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;
  
  MapPoint({required this.coordinates, this.name});

  // If this is Stop use the properly translated fields (englishName)
  String getLocalizedName(AppLocalizations l10n) {
    if (this is Stop) {
      return l10n.localeName == "en" ? (this as Stop).englishName : name!;
    }
    return name ?? l10n.chosenPoint;
  }

  String getLatLngAsString() {
    return "${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°";
  }
}