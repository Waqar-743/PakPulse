/// A live atmospheric reading plus a next-day forecast, sourced from the
/// free, no-API-key Open-Meteo service. Forecast fields are nullable so the
/// model degrades gracefully if only the current reading is available.
class LiveConditions {
  final double latitude;
  final double longitude;
  final double temperatureC;
  final double precipitationMmLastHour;
  final double humidityPercent;
  final int weatherCode;
  final DateTime observedAt;
  final String? attribution;

  // ── Next-day forecast (nullable — may be absent) ────────────────────────────
  final double? forecastMaxTempC;
  final double? forecastMinTempC;
  final double? forecastPrecipMm;
  final double? forecastPrecipProbability;
  final DateTime? forecastDate;

  const LiveConditions({
    required this.latitude,
    required this.longitude,
    required this.temperatureC,
    required this.precipitationMmLastHour,
    required this.humidityPercent,
    required this.weatherCode,
    required this.observedAt,
    this.attribution,
    this.forecastMaxTempC,
    this.forecastMinTempC,
    this.forecastPrecipMm,
    this.forecastPrecipProbability,
    this.forecastDate,
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

  // ── Risk assessment (Pakistan-calibrated) ──────────────────────────────────

  /// Heatwave risk for tomorrow, derived from the forecast max temperature.
  /// Pakistan's NDMA treats sustained 40°C+ as a heat-action trigger.
  HazardRisk get heatwaveRisk {
    final t = forecastMaxTempC;
    if (t == null) return HazardRisk.unknown;
    if (t >= 45) return HazardRisk.extreme;
    if (t >= 40) return HazardRisk.high;
    if (t >= 36) return HazardRisk.moderate;
    return HazardRisk.low;
  }

  /// Flood risk for tomorrow, derived from forecast rainfall + probability.
  HazardRisk get floodRisk {
    final mm = forecastPrecipMm;
    final prob = forecastPrecipProbability;
    if (mm == null && prob == null) return HazardRisk.unknown;
    final rain = mm ?? 0;
    final p = prob ?? 0;
    if (rain >= 50 || p >= 85) return HazardRisk.extreme;
    if (rain >= 25 || p >= 65) return HazardRisk.high;
    if (rain >= 8 || p >= 40) return HazardRisk.moderate;
    return HazardRisk.low;
  }

  bool get hasForecast => forecastMaxTempC != null;
}

/// Severity of a forecast-derived hazard.
enum HazardRisk { unknown, low, moderate, high, extreme }

extension HazardRiskLabel on HazardRisk {
  String get label {
    switch (this) {
      case HazardRisk.unknown:
        return 'Unknown';
      case HazardRisk.low:
        return 'Low';
      case HazardRisk.moderate:
        return 'Moderate';
      case HazardRisk.high:
        return 'High';
      case HazardRisk.extreme:
        return 'Extreme';
    }
  }
}
