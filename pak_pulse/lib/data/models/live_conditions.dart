class LiveConditions {
  final double latitude;
  final double longitude;
  final double temperatureC;
  final double precipitationMmLastHour;
  final double humidityPercent;
  final int weatherCode;
  final DateTime observedAt;
  final String? attribution;

  const LiveConditions({
    required this.latitude,
    required this.longitude,
    required this.temperatureC,
    required this.precipitationMmLastHour,
    required this.humidityPercent,
    required this.weatherCode,
    required this.observedAt,
    this.attribution,
  });

  /// WMO weather codes — quick human-readable label
  String get weatherLabel {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Cloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Fog';
    if (weatherCode >= 51 && weatherCode <= 57) return 'Drizzle';
    if (weatherCode >= 61 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Unknown';
  }
}
