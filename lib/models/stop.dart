class Stop {
  final String stopId, name;
  final double latitude, longitude;
  final String? englishName; // Back to final!

  const Stop({
    required this.stopId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.englishName,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode == 'en' && englishName != null && englishName!.isNotEmpty) {
      return englishName!;
    }
    return name;
  }

  factory Stop.fromCsv(
      List<dynamic> row,
      Map<String, int> headerIndices, {
        String? englishName,
      }) {
    return Stop(
      stopId: row[headerIndices['stop_id']!].toString(),
      name: row[headerIndices['stop_name']!].toString(),
      latitude: double.parse(row[headerIndices['stop_lat']!].toString()),
      longitude: double.parse(row[headerIndices['stop_lon']!].toString()),
      englishName: englishName,
    );
  }
}