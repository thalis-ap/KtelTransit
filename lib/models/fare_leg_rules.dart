/// A rule that links a fare product to a specific leg of travel (a route,
/// network, or area). See fare_leg_rules.txt in the GTFS-Fares v2 spec.
class FareLegRule {
  /// Identifies a group of entries in fare_leg_rules.txt that can be
  /// referenced by fare_transfer_rules.txt. Optional.
  final String? legGroupId;

  /// Identifies a route network (from networks.txt) that this rule applies to.
  /// Optional. If empty, the rule applies based on other criteria (e.g., areas).
  final String? networkId;

  /// Identifies a departure area (from areas.txt). Optional.
  final String? fromAreaId;

  /// Identifies an arrival area (from areas.txt). Optional.
  final String? toAreaId;

  /// Defines the timeframe for the start of the fare leg. Optional.
  final String? fromTimeframeGroupId;

  /// Defines the timeframe for the end of the fare leg. Optional.
  final String? toTimeframeGroupId;

  /// The fare product required to travel this leg. Required.
  final String fareProductId;

  static const legGroupIdKey = 'leg_group_id';
  static const networkIdKey = 'network_id';
  static const fromAreaIdKey = 'from_area_id';
  static const toAreaIdKey = 'to_area_id';
  static const fromTimeframeGroupIdKey = 'from_timeframe_group_id';
  static const toTimeframeGroupIdKey = 'to_timeframe_group_id';
  static const fareProductIdKey = 'fare_product_id';

  static const List<String> requiredFields = [
    fareProductIdKey,
  ];

  const FareLegRule({
    this.legGroupId,
    this.networkId,
    this.fromAreaId,
    this.toAreaId,
    this.fromTimeframeGroupId,
    this.toTimeframeGroupId,
    required this.fareProductId,
  });

  factory FareLegRule.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices,
      ) {
    String? getOptional(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return null;
      final value = row[idx].toString().trim();
      return value.isEmpty ? null : value;
    }

    String getRequired(String key) {
      return getOptional(key) ?? ''; // Will be validated separately
    }

    return FareLegRule(
      legGroupId: getOptional(legGroupIdKey),
      networkId: getOptional(networkIdKey),
      fromAreaId: getOptional(fromAreaIdKey),
      toAreaId: getOptional(toAreaIdKey),
      fromTimeframeGroupId: getOptional(fromTimeframeGroupIdKey),
      toTimeframeGroupId: getOptional(toTimeframeGroupIdKey),
      fareProductId: getRequired(fareProductIdKey),
    );
  }

  static bool hasRequiredHeaders(Map<String, int> headers) {
    for (final field in requiredFields) {
      if (!headers.containsKey(field)) return false;
    }
    return true;
  }

  static bool isValidRow(List<dynamic> row, Map<String, int> headers) {
    final index = headers[fareProductIdKey]!;
    if (index >= row.length || row[index].toString().trim().isEmpty) {
      return false;
    }
    return true;
  }
}