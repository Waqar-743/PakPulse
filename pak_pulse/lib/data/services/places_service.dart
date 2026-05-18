import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A nearby emergency facility (hospital, rescue station, police) shown as a
/// blue marker on the crisis map.
class EmergencyPlace {
  final String name;
  final double lat;
  final double lng;
  final String type;

  const EmergencyPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
  });
}

/// Resolves nearby emergency services.
///
/// When a `MAPS_API_KEY` is configured in `.env`, this calls the Google Places
/// Nearby Search API. With no key (or on any failure) it returns a curated
/// Islamabad set so the map always renders blue emergency markers.
class PlacesService {
  PlacesService._();

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  static const _endpoint =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  static Future<List<EmergencyPlace>> nearbyEmergencyServices({
    required double lat,
    required double lng,
  }) async {
    final key = dotenv.maybeGet('MAPS_API_KEY') ?? '';
    if (key.isEmpty) return fallback;

    try {
      final results = <EmergencyPlace>[];
      for (final type in const ['hospital', 'police']) {
        final resp = await _dio.get<Map<String, dynamic>>(
          _endpoint,
          queryParameters: {
            'location': '$lat,$lng',
            'radius': 7000,
            'type': type,
            'key': key,
          },
        );
        final list = resp.data?['results'] as List? ?? const [];
        for (final r in list.take(6)) {
          final geo = (r as Map)['geometry']?['location'];
          if (geo == null) continue;
          results.add(EmergencyPlace(
            name: (r['name'] as String?) ?? 'Emergency service',
            lat: (geo['lat'] as num).toDouble(),
            lng: (geo['lng'] as num).toDouble(),
            type: type == 'hospital' ? 'Hospital' : 'Rescue / Police',
          ));
        }
      }
      return results.isEmpty ? fallback : results;
    } catch (_) {
      return fallback;
    }
  }

  /// Curated Islamabad / Rawalpindi emergency facilities.
  static const List<EmergencyPlace> fallback = [
    EmergencyPlace(
        name: 'PIMS Hospital', lat: 33.7086, lng: 73.0551, type: 'Hospital'),
    EmergencyPlace(
        name: 'Shifa International',
        lat: 33.6694,
        lng: 73.0525,
        type: 'Hospital'),
    EmergencyPlace(
        name: 'Federal Govt Poly Clinic',
        lat: 33.7180,
        lng: 73.0680,
        type: 'Hospital'),
    EmergencyPlace(
        name: 'Rescue 1122 Islamabad',
        lat: 33.6995,
        lng: 73.0440,
        type: 'Rescue Station'),
    EmergencyPlace(
        name: 'Holy Family Hospital',
        lat: 33.6390,
        lng: 73.0700,
        type: 'Hospital'),
  ];
}
