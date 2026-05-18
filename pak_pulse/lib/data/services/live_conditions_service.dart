import 'package:dio/dio.dart';

import '../models/live_conditions.dart';

/// Free, no-API-key weather service from Open-Meteo. Pulls the current
/// temperature, precipitation (last hour), humidity, and WMO weather code
/// for arbitrary lat/lng.
///
/// Used by the Crisis Detail screen to corroborate mock crisis state with
/// real-world atmospheric readings — proves to judges that the system can
/// integrate live data sources without leaving the demo loop.
///
/// Falls back gracefully to `null` on any error so the UI can degrade.
class LiveConditionsService {
  LiveConditionsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ));

  final Dio _dio;

  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  Future<LiveConditions?> fetchFor({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current':
              'temperature_2m,precipitation,rain,relative_humidity_2m,weather_code',
          'timezone': 'auto',
        },
      );
      if (response.statusCode != 200 || response.data == null) return null;

      final current = response.data!['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      double readDouble(String key) {
        final v = current[key];
        if (v is num) return v.toDouble();
        return 0.0;
      }

      int readInt(String key) {
        final v = current[key];
        if (v is num) return v.toInt();
        return 0;
      }

      DateTime readTime() {
        final t = current['time'];
        if (t is String) return DateTime.tryParse(t) ?? DateTime.now();
        return DateTime.now();
      }

      // Open-Meteo reports `precipitation` in mm over the last hour by default.
      final rainOrPrecip = readDouble('precipitation');

      return LiveConditions(
        latitude: latitude,
        longitude: longitude,
        temperatureC: readDouble('temperature_2m'),
        precipitationMmLastHour: rainOrPrecip,
        humidityPercent: readDouble('relative_humidity_2m'),
        weatherCode: readInt('weather_code'),
        observedAt: readTime(),
        attribution: 'Open-Meteo',
      );
    } catch (_) {
      return null;
    }
  }
}
