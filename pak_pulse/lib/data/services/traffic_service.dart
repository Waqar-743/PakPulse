import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/road_incident.dart';

/// Pulls real road incidents (closures, jams, accidents, road works) from the
/// TomTom Traffic Incidents API. Free tier — key read from `.env`
/// (`TOMTOM_API_KEY`). Returns an empty list on any error or when no key is
/// configured, so the UI degrades to "no live data" rather than breaking.
///
/// Note: TomTom incident coverage for Pakistani cities is sparse — an empty
/// result is a *real* answer ("no active incidents"), not a failure.
class TrafficService {
  TrafficService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  final Dio _dio;

  static const _endpoint =
      'https://api.tomtom.com/traffic/services/5/incidentDetails';

  String get _apiKey => (dotenv.maybeGet('TOMTOM_API_KEY') ?? '').trim();

  bool get hasKey => _apiKey.isNotEmpty;

  /// Fetches incidents within a box centred on [lat]/[lng].
  /// [radiusDegrees] ≈ 0.22 covers roughly a 25 km span.
  Future<List<RoadIncident>> fetchIncidents({
    required double lat,
    required double lng,
    double radiusDegrees = 0.22,
  }) async {
    if (_apiKey.isEmpty) return const [];
    try {
      final minLon = lng - radiusDegrees;
      final minLat = lat - radiusDegrees;
      final maxLon = lng + radiusDegrees;
      final maxLat = lat + radiusDegrees;

      final response = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {
          'key': _apiKey,
          'bbox': '$minLon,$minLat,$maxLon,$maxLat',
          'fields':
              '{incidents{type,geometry{type,coordinates},properties{iconCategory,magnitudeOfDelay,events{description,code},from,to,length,delay}}}',
          'language': 'en-GB',
          'timeValidityFilter': 'present',
        },
      );
      if (response.statusCode != 200 || response.data == null) return const [];

      final incidents = response.data!['incidents'] as List?;
      if (incidents == null) return const [];

      final result = <RoadIncident>[];
      for (final raw in incidents) {
        final m = raw as Map;
        final props = m['properties'] as Map?;
        if (props == null) continue;

        final events = props['events'] as List?;
        final firstEvent =
            (events != null && events.isNotEmpty) ? events.first as Map : null;

        // Geometry first coordinate → marker position.
        double? lat0, lng0;
        final geom = m['geometry'] as Map?;
        final coords = geom?['coordinates'];
        if (coords is List && coords.isNotEmpty) {
          final type = geom?['type'];
          final point = type == 'Point' ? coords : coords.first;
          if (point is List && point.length >= 2) {
            lng0 = (point[0] as num?)?.toDouble();
            lat0 = (point[1] as num?)?.toDouble();
          }
        }

        result.add(RoadIncident(
          iconCategory: (props['iconCategory'] as num?)?.toInt() ?? 0,
          magnitudeOfDelay: (props['magnitudeOfDelay'] as num?)?.toInt() ?? 0,
          from: (props['from'] ?? '').toString(),
          to: (props['to'] ?? '').toString(),
          lengthMeters: (props['length'] as num?)?.toDouble() ?? 0,
          delaySeconds: (props['delay'] as num?)?.toInt(),
          description: (firstEvent?['description'] ?? '').toString(),
          lat: lat0,
          lng: lng0,
        ));
      }

      // Most disruptive first.
      result.sort((a, b) {
        if (a.isBlockage != b.isBlockage) return a.isBlockage ? -1 : 1;
        return b.magnitudeOfDelay.compareTo(a.magnitudeOfDelay);
      });
      return result;
    } catch (_) {
      return const [];
    }
  }
}
