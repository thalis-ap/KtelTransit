import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Result of a location permission check.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Handles all location-related operations.
class LocationService {
  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks the current permission status.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Requests location permission from the user.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Comprehensive check: returns the status and handles service/permission checks.
  /// If the user needs to open settings, this returns [LocationPermissionStatus.deniedForever]
  /// or [LocationPermissionStatus.serviceDisabled] accordingly.
  Future<LocationPermissionStatus> getPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  /// Gets the last known position (fast, may be stale).
  Future<LatLng?> getLastKnownPosition() async {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
    return LatLng(position.latitude, position.longitude);
  }

  /// Gets the current position (accurate, may take a moment).
  /// Returns null if permission is denied or location is unavailable.
  Future<LatLng?> getCurrentPosition({LocationAccuracy accuracy = LocationAccuracy.medium}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: tries last known first, then falls back to current.
  Future<LatLng?> getBestAvailableLocation({LocationAccuracy accuracy = LocationAccuracy.medium}) async {
    final last = await getLastKnownPosition();
    if (last != null) return last;

    return await getCurrentPosition(accuracy: accuracy);
  }
}