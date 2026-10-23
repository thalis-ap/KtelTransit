class Calendar {
  final String serviceId;
  final bool monday, tuesday, wednesday, thursday, friday, saturday, sunday;
  final String startDate, endDate;

  static const _serviceIdKey = 'service_id';
  static const _mondayKey = 'monday';
  static const _tuesdayKey = 'tuesday';
  static const _wednesdayKey = 'wednesday';
  static const _thursdayKey = 'thursday';
  static const _fridayKey = 'friday';
  static const _saturdayKey = 'saturday';
  static const _sundayKey = 'sunday';
  static const _startDateKey = 'start_date';
  static const _endDateKey = 'end_date';

  static const List<String> requiredFields = [
    _serviceIdKey,
    _mondayKey,
    _tuesdayKey,
    _wednesdayKey,
    _thursdayKey,
    _fridayKey,
    _saturdayKey,
    _sundayKey,
    _startDateKey,
    _endDateKey,
  ];

  const Calendar({
    required this.serviceId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.startDate,
    required this.endDate,
  });

  factory Calendar.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return Calendar(
      serviceId: getValue(_serviceIdKey),
      monday: getValue(_mondayKey) == '1',
      tuesday: getValue(_tuesdayKey) == '1',
      wednesday: getValue(_wednesdayKey) == '1',
      thursday: getValue(_thursdayKey) == '1',
      friday: getValue(_fridayKey) == '1',
      saturday: getValue(_saturdayKey) == '1',
      sunday: getValue(_sundayKey) == '1',
      startDate: getValue(_startDateKey),
      endDate: getValue(_endDateKey),
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