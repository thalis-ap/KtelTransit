/// Defines the cost and conditions for a transfer between two fare legs.
/// See fare_transfer_rules.txt in the GTFS-Fares v2 spec.
class FareTransferRule {
  /// The leg group from which the passenger is transferring. Optional.
  /// An empty value means "any leg group not explicitly listed".
  final String? fromLegGroupId;

  /// The leg group to which the passenger is transferring. Optional.
  /// An empty value means "any leg group not explicitly listed".
  final String? toLegGroupId;

  /// How many consecutive transfers this rule can be applied to.
  /// Required if fromLegGroupId == toLegGroupId; otherwise forbidden.
  /// -1 means unlimited.
  final int? transferCount;

  /// The time limit for the transfer, in seconds. Optional.
  final int? durationLimit;

  /// Defines the start/end reference points for the durationLimit.
  /// Required if durationLimit is set. (0-3)
  final int? durationLimitType;

  /// The cost processing method for the transfer (0, 1, or 2). Required.
  final int fareTransferType;

  /// The fare product required for this transfer. Optional.
  /// If empty, the transfer cost is 0.
  final String? fareProductId;

  static const fromLegGroupIdKey = 'from_leg_group_id';
  static const toLegGroupIdKey = 'to_leg_group_id';
  static const transferCountKey = 'transfer_count';
  static const durationLimitKey = 'duration_limit';
  static const durationLimitTypeKey = 'duration_limit_type';
  static const fareTransferTypeKey = 'fare_transfer_type';
  static const fareProductIdKey = 'fare_product_id';

  static const List<String> requiredFields = [
    fareTransferTypeKey,
  ];

  const FareTransferRule({
    this.fromLegGroupId,
    this.toLegGroupId,
    this.transferCount,
    this.durationLimit,
    this.durationLimitType,
    required this.fareTransferType,
    this.fareProductId,
  });

  factory FareTransferRule.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices,
      ) {
    String? getOptional(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return null;
      final value = row[idx].toString().trim();
      return value.isEmpty ? null : value;
    }

    int? getOptionalInt(String key) {
      final value = getOptional(key);
      return value != null ? int.tryParse(value) : null;
    }

    final fareTransferTypeStr = getOptional(fareTransferTypeKey) ?? '';
    final fareTransferType = int.tryParse(fareTransferTypeStr) ?? 0;

    return FareTransferRule(
      fromLegGroupId: getOptional(fromLegGroupIdKey),
      toLegGroupId: getOptional(toLegGroupIdKey),
      transferCount: getOptionalInt(transferCountKey),
      durationLimit: getOptionalInt(durationLimitKey),
      durationLimitType: getOptionalInt(durationLimitTypeKey),
      fareTransferType: fareTransferType,
      fareProductId: getOptional(fareProductIdKey),
    );
  }

  static bool hasRequiredHeaders(Map<String, int> headers) {
    for (final field in requiredFields) {
      if (!headers.containsKey(field)) return false;
    }
    return true;
  }

  static bool isValidRow(List<dynamic> row, Map<String, int> headers) {
    final index = headers[fareTransferTypeKey]!;
    if (index >= row.length || row[index].toString().trim().isEmpty) {
      return false;
    }
    // Ensure fare_transfer_type is a valid integer (0, 1, or 2)
    final typeStr = row[index].toString().trim();
    final type = int.tryParse(typeStr);
    if (type == null || !(type >= 0 && type <= 2)) {
      return false;
    }
    return true;
  }
}