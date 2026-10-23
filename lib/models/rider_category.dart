/// A group of riders eligible for specific fares (adult, student, senior, ...).
/// See rider_categories.txt in the GTFS-Fares v2 spec.
class RiderCategory {
  final String riderCategoryId;

  /// Already translated when a translation exists. Falls back to the id.
  final String name;

  /// True for the category that applies when the rider doesn't pick one
  /// (is_default_fare_category = 1).
  final bool isDefault;

  /// Optional page explaining who is eligible for this category and which
  /// documents are needed. Null when not provided.
  final String? eligibilityUrl;

  static const riderCategoryIdKey = 'rider_category_id';
  static const riderCategoryNameKey = 'rider_category_name';
  static const isDefaultKey = 'is_default_fare_category';
  static const eligibilityUrlKey = 'eligibility_url';

  static const List<String> requiredFields = [
    riderCategoryIdKey,
    riderCategoryNameKey,
  ];

  const RiderCategory({
    required this.riderCategoryId,
    required this.name,
    this.isDefault = false,
    this.eligibilityUrl,
  });

  factory RiderCategory.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedName,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final id = getValue(riderCategoryIdKey);
    final resolvedName = translatedName ?? getValue(riderCategoryNameKey);
    final url = getValue(eligibilityUrlKey);

    return RiderCategory(
      riderCategoryId: id,
      name: resolvedName.isEmpty ? id : resolvedName,
      isDefault: getValue(isDefaultKey) == '1',
      eligibilityUrl: url.isEmpty ? null : url,
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
    return true;
  }
}