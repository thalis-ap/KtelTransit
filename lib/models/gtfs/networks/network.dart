/// A logical group of routes that share a fare structure (a "network").
/// See networks.txt in the GTFS-Fares v2 spec.
///
/// Optional file. Its presence is "conditionally forbidden" alongside a
/// network_id column in routes.txt — a feed must pick one approach or the
/// other, never both. The current KTEL feeds use neither, so they are free
/// to add this file without touching routes.txt.
class Network {
  final String networkId;

  /// Already translated when a translation exists. Falls back to the id,
  /// since network_name is optional in the spec.
  final String name;

  static const networkIdKey = 'network_id';
  static const networkNameKey = 'network_name';

  static const List<String> requiredFields = [
    networkIdKey,
  ];

  const Network({
    required this.networkId,
    required this.name,
  });

  /// False when the region gave no name, so [name] is just the raw id.
  /// The UI can then show a generic label instead.
  bool get hasName => name != networkId;

  factory Network.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? translatedName,
      }) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final id = getValue(networkIdKey);
    final rawName = getValue(networkNameKey);
    final resolvedName = translatedName ?? rawName;

    return Network(
      networkId: id,
      name: resolvedName.isEmpty ? id : resolvedName,
    );
  }

  static bool hasRequiredHeaders(Map<String, int> headers) {
    for (final field in requiredFields) {
      if (!headers.containsKey(field)) return false;
    }
    return true;
  }

  static bool isValidRow(List<dynamic> row, Map<String, int> headers) {
    final index = headers[networkIdKey]!;
    if (index >= row.length || row[index].toString().trim().isEmpty) {
      return false;
    }
    return true;
  }
}