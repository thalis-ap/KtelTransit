import '../l10n/app_localizations.dart';

/// Formats raw meter distances into localized, human readable strings,
/// mirroring the pattern used by TimeFormat.
class DistanceFormat {
  /// Distances under 1km are shown in meters (rounded), otherwise in km
  /// with 1 decimal place.
  static String metersToFormattedString(double meters, AppLocalizations l10n) {
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return l10n.kilometersFormat(km);
    }
    return l10n.metersFormat(meters.round());
  }
}