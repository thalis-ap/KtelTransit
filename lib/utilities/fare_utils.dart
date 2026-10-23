import 'package:intl/intl.dart';

/// Formats fare amounts using the currency each fare product carries,
/// mirroring the pattern used by DistanceFormat and TimeFormat.
class FareFormat {
  static String fareAsString(double? fare) {
    return fare != null ? "${fare.toStringAsFixed(2)}€" : "-€";
  }

  static String formatPrice(double amount, String currency) {
    final symbol = currency == 'EUR' ? '€' : currency;
    return "${amount.toStringAsFixed(2)}$symbol";
  }

  /// Formats [amount] in the given ISO 4217 [currency], following the
  /// conventions of the active language (e.g. "2,20 €" in Greek, "€2.20" in
  /// English). Falls back to a plain "2.20 EUR" style if formatting fails.
  static String amountToFormattedString(
      double amount,
      String currency,
      String languageCode,
      ) {
    try {
      return NumberFormat.simpleCurrency(
        locale: languageCode,
        name: currency,
      ).format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}