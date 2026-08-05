class Calendar {
  final String serviceId;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final String startDate;
  final String endDate;

  Calendar({
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

  factory Calendar.fromCsv(List<dynamic> row, Map<String, int> headerIndex) {
    return Calendar(
      serviceId: row[headerIndex['service_id']!].toString(),
      monday: row[headerIndex['monday']!] == 1 || row[headerIndex['monday']!] == '1',
      tuesday: row[headerIndex['tuesday']!] == 1 || row[headerIndex['tuesday']!] == '1',
      wednesday: row[headerIndex['wednesday']!] == 1 || row[headerIndex['wednesday']!] == '1',
      thursday: row[headerIndex['thursday']!] == 1 || row[headerIndex['thursday']!] == '1',
      friday: row[headerIndex['friday']!] == 1 || row[headerIndex['friday']!] == '1',
      saturday: row[headerIndex['saturday']!] == 1 || row[headerIndex['saturday']!] == '1',
      sunday: row[headerIndex['sunday']!] == 1 || row[headerIndex['sunday']!] == '1',
      startDate: row[headerIndex['start_date']!].toString(),
      endDate: row[headerIndex['end_date']!].toString(),
    );
  }
}