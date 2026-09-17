class Agency {
  final String agencyId, name, url, timezone, phone, email, fareUrl;

  static const agencyIdKey = 'agency_id';
  static const agencyNameKey = 'agency_name';
  static const agencyUrlKey = 'agency_url';
  static const agencyTimezoneKey = 'agency_timezone';
  static const agencyPhoneKey = 'agency_phone';
  static const agencyFareUrlKey = 'agency_fare_url';
  static const agencyEmailKey = 'agency_email';

  static const List<String> requiredFields = [
    agencyIdKey,
    agencyNameKey,
    agencyUrlKey,
    agencyTimezoneKey,
  ];

  const Agency({
    required this.agencyId,
    required this.name,
    required this.url,
    required this.timezone,
    required this.phone,
    required this.email,
    required this.fareUrl,
  });

  factory Agency.fromCsv(List<dynamic> row, Map<String, int> headerIndices, {String? translatedName}) {
    String getValue(String key) {
      final idx = headerIndices[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    String rawName = getValue(agencyNameKey);

    return Agency(
      agencyId: getValue(agencyIdKey),
      name: translatedName ?? rawName,
      url: getValue(agencyUrlKey),
      timezone: getValue(agencyTimezoneKey),
      phone: getValue(agencyPhoneKey),
      email: getValue(agencyEmailKey),
      fareUrl: getValue(agencyFareUrlKey),
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
      // A row is invalid if it's too short OR if a required field is empty
      if (index >= row.length || row[index].toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }
}
