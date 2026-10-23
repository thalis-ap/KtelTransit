class CalendarDate {
  final String serviceId;
  final String date; // Format: YYYYMMDD
  final int exceptionType; // 1 for added, 2 for removed

  static const _serviceIdKey = 'service_id';
  static const _dateKey = 'date';
  static const _exceptionTypeKey = 'exception_type';

  static const List<String> requiredFields = [
    _serviceIdKey,
    _dateKey,
    _exceptionTypeKey,
  ];

  CalendarDate({
    required this.serviceId,
    required this.date,
    required this.exceptionType,
  });

  factory CalendarDate.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return CalendarDate(
      serviceId: getValue(_serviceIdKey),
      date: getValue(_dateKey),
      exceptionType: int.parse(getValue(_exceptionTypeKey)),
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

    // Ensure exception_type is a valid integer to prevent int.parse crashes
    final typeStr = row[headers[_exceptionTypeKey]!].toString().trim();
    if (int.tryParse(typeStr) == null) {
      return false;
    }

    return true;
  }
}