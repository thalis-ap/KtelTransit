/// Something a passenger can buy (single ticket, day pass, monthly card, ...).
/// See fare_products.txt in the GTFS-Fares v2 spec.
///
/// The primary key in the spec is (fare_product_id, fare_media_id), so the
/// same [fareProductId] can appear several times with different media and
/// different prices. Never index by [fareProductId] alone, use [key].
class FareProduct {
  final String fareProductId;

  /// Already translated when a translation exists. Falls back to the id,
  /// since fare_product_name is optional in the spec.
  final String name;

  /// The media this product (and price) applies to. Null means the product
  /// is valid on any media (empty fare_media_id in the file).
  final String? fareMediaId;

  /// Can be negative (the spec uses this for transfer discounts).
  final double amount;

  /// ISO 4217 currency code, always upper case (e.g. EUR).
  final String currency;

  static const fareProductIdKey = 'fare_product_id';
  static const fareProductNameKey = 'fare_product_name';
  static const fareMediaIdKey = 'fare_media_id';
  static const amountKey = 'amount';
  static const currencyKey = 'currency';

  static const List<String> requiredFields = [
    fareProductIdKey,
    amountKey,
    currencyKey,
  ];

  const FareProduct({
    required this.fareProductId,
    required this.name,
    required this.amount,
    required this.currency,
    this.fareMediaId,
  });

  /// Unique key of the product row: fare_product_id + fare_media_id
  String get key => '$fareProductId|${fareMediaId ?? ''}';

  /// True when the product is not tied to a specific media
  bool get isValidOnAnyMedia => fareMediaId == null;

  /// Negative amounts are legal but are discounts, not something to buy.
  /// The catalog UI should probably hide these.
  bool get isDiscount => amount < 0;

  factory FareProduct.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedName,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final id = getValue(fareProductIdKey);
    final rawName = getValue(fareProductNameKey);
    final resolvedName = translatedName ?? rawName;
    final mediaId = getValue(fareMediaIdKey);

    return FareProduct(
      fareProductId: id,
      name: resolvedName.isEmpty ? id : resolvedName,
      fareMediaId: mediaId.isEmpty ? null : mediaId,
      amount: double.parse(getValue(amountKey)),
      currency: getValue(currencyKey).toUpperCase(),
    );
  }

  static bool hasRequiredHeaders(Map<String, int> headers) {
    for (final field in requiredFields) {
      if (!headers.containsKey(field)) return false;
    }
    return true;
  }

  static bool isValidRow(List<dynamic> row, Map<String, int> headers) {
    for (final field in requiredFields) {
      final index = headers[field]!;
      if (index >= row.length || row[index].toString().trim().isEmpty) {
        return false;
      }
    }

    // Ensure amount is a valid number to prevent double.parse crashes
    final amountStr = row[headers[amountKey]!].toString().trim();
    if (double.tryParse(amountStr) == null) {
      return false;
    }

    // Ensure currency looks like an ISO 4217 code (3 letters)
    final currencyStr = row[headers[currencyKey]!].toString().trim();
    if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currencyStr)) {
      return false;
    }

    return true;
  }
}