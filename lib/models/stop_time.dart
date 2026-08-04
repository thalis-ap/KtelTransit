class StopTime {
  final String tripId, arrivalTime, departureTime, stopId;
  final int stopSequence;

  const StopTime({required this.tripId, required this.arrivalTime, required this.departureTime, required this.stopId, required this.stopSequence});

  factory StopTime.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    return StopTime(
      tripId: row[headerIndices['trip_id']!].toString(),
      stopId: row[headerIndices['stop_id']!].toString(),
      arrivalTime: row[headerIndices['arrival_time']!].toString(),
      departureTime: row[headerIndices['departure_time']!].toString(),
      stopSequence: int.parse(row[headerIndices['stop_sequence']!].toString()),
    );
  }
}