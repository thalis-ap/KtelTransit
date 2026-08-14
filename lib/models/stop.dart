class Stop {
  final String stopId, name;
  final double latitude, longitude;
  final String englishName;

  const Stop({
    required this.stopId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.englishName,
  });

  String getLocalizedName(String languageCode) {
    return languageCode == 'en' ? englishName : name;
  }

  factory Stop.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? englishName,
      }) {
    final String stopName = row[headerIndices['stop_name']!].toString();
    return Stop(
      stopId: row[headerIndices['stop_id']!].toString(),
      name: stopName,
      latitude: double.parse(row[headerIndices['stop_lat']!].toString()),
      longitude: double.parse(row[headerIndices['stop_lon']!].toString()),
      englishName: englishName ?? stopName,
    );
  }
}