class Stop {
  final String stopId, name;
  final double latitude, longitude;

  const Stop({required this.stopId, required this.name, required this.latitude, required this.longitude});

  factory Stop.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    return Stop(
      stopId: row[headerIndices['stop_id']!].toString(),
      name: row[headerIndices['stop_name']!].toString(),
      latitude: double.parse(row[headerIndices['stop_lat']!].toString()),
      longitude: double.parse(row[headerIndices['stop_lon']!].toString()),
    );
  }
}