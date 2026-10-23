class StopTime {
  final String tripId, arrivalTime, departureTime, stopId;
  final int stopSequence;

  static const tripIdKey = 'trip_id';
  static const stopIdKey = 'stop_id';
  static const arrivalTimeKey = 'arrival_time';
  static const departureTimeKey = 'departure_time';
  static const stopSequenceKey = 'stop_sequence';

  static const List<String> requiredFields = [
    tripIdKey,
    stopIdKey,
    arrivalTimeKey,
    departureTimeKey,
    stopSequenceKey,
  ];

  const StopTime({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    required this.stopSequence,
  });

  factory StopTime.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return StopTime(
      tripId: getValue(tripIdKey),
      stopId: getValue(stopIdKey),
      arrivalTime: getValue(arrivalTimeKey),
      departureTime: getValue(departureTimeKey),
      stopSequence: int.parse(getValue(stopSequenceKey)),
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

    // Ensure stop_sequence is a valid integer to prevent int.parse crashes
    final seqStr = row[headers[stopSequenceKey]!].toString().trim();
    if (int.tryParse(seqStr) == null) {
      return false;
    }

    return true;
  }
}