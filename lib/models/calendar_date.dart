class CalendarDate {
  final String serviceId;
  final String date; // Format: YYYYMMDD
  final int exceptionType; // 1 for added, 2 for removed

  CalendarDate({
    required this.serviceId,
    required this.date,
    required this.exceptionType,
  });
}