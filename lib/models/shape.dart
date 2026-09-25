class Shape {
  final String shapeId;
  final double latitude, longitude;
  final int sequence;

  static const shapeIdKey = "shape_id";
  static const shapePtLatitudeKey = "shape_pt_lat";
  static const shapePtLongitudeKey = "shape_pt_lon";
  static const shapePtSequenceKey = "shape_pt_sequence";
  
  static const List<String> requiredFields = [
    shapeIdKey,
    shapePtLatitudeKey,
    shapePtLongitudeKey,
    shapePtSequenceKey,
  ];

  const Shape({
    required this.shapeId,
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  factory Shape.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return Shape(
      shapeId: getValue(shapeIdKey),
      latitude: double.parse(getValue(shapePtLatitudeKey)),
      longitude: double.parse(getValue(shapePtLongitudeKey)),
      sequence: int.parse(getValue(shapePtSequenceKey)),
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

    // Ensure shape_pt_sequence is a valid integer to prevent int.parse crashes
    final ptStr = row[headers[shapePtSequenceKey]!].toString().trim();
    if (int.tryParse(ptStr) == null) {
      return false;
    }
    
    // Ensure shape_pt_lat/lon are valid doubles
    final ptLat = row[headers[shapePtLatitudeKey]!].toString().trim();
    final ptLon = row[headers[shapePtLongitudeKey]!].toString().trim();
    if (double.tryParse(ptLat) == null || double.tryParse(ptLon) == null) {
      return false;
    }

    return true;
  }
}
