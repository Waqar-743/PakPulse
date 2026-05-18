import 'package:latlong2/latlong.dart';

import '../../core/constants/islamabad_sectors.dart';

class ReroutePlan {
  final String blockedRoute;
  final String alternateRoute;
  final List<LatLng> alternatePolyline;
  final int timeAddedMinutes;
  final Map<String, dynamic> response;

  const ReroutePlan({
    required this.blockedRoute,
    required this.alternateRoute,
    required this.alternatePolyline,
    required this.timeAddedMinutes,
    required this.response,
  });
}

class RerouteTool {
  RerouteTool._();

  static ReroutePlan computeReroute({
    required String sector,
    required String crisisType,
  }) {
    final s = sector.toUpperCase();

    if (s.contains('G-10')) {
      final origin = IslamabadSectors.resolve('G-10') ?? const LatLng(33.69, 73.0228);
      final polyline = [
        origin,
        const LatLng(33.6920, 73.0290),
        const LatLng(33.6960, 73.0370),
        const LatLng(33.7050, 73.0480),
        const LatLng(33.7160, 73.0560),
      ];
      return ReroutePlan(
        blockedRoute: 'G-10 Markaz underpass (flooded)',
        alternateRoute: 'Service Road Eastern → 9th Avenue',
        alternatePolyline: polyline,
        timeAddedMinutes: 12,
        response: {
          'status': 'REROUTE_ACTIVE',
          'blocked': 'G-10 Markaz underpass',
          'alternate': 'Service Road Eastern → 9th Avenue',
          'distance_added_km': 2.4,
          'time_added_minutes': 12,
          'estimated_commuters_affected': 30000,
          'message': 'Traffic diverted via Service Road Eastern. ITP officers deployed at junction.',
        },
      );
    }

    if (s.contains('FAIZABAD')) {
      final origin = IslamabadSectors.resolve('Faizabad') ?? const LatLng(33.6938, 73.0651);
      final polyline = [
        origin,
        const LatLng(33.7010, 73.0700),
        const LatLng(33.7090, 73.0680),
        const LatLng(33.7150, 73.0620),
        const LatLng(33.7200, 73.0560),
      ];
      return ReroutePlan(
        blockedRoute: 'Faizabad Interchange (protest)',
        alternateRoute: '9th Avenue → Margalla Road',
        alternatePolyline: polyline,
        timeAddedMinutes: 18,
        response: {
          'status': 'REROUTE_ACTIVE',
          'blocked': 'Faizabad Interchange',
          'alternate': '9th Avenue → Margalla Road',
          'distance_added_km': 4.1,
          'time_added_minutes': 18,
          'estimated_commuters_affected': 75000,
          'message': 'Major reroute active. All traffic to Rawalpindi diverted via 9th Avenue corridor.',
        },
      );
    }

    final origin = IslamabadSectors.resolve(sector) ?? const LatLng(33.69, 73.04);
    final polyline = [
      origin,
      LatLng(origin.latitude + 0.005, origin.longitude + 0.005),
      LatLng(origin.latitude + 0.010, origin.longitude + 0.012),
    ];
    return ReroutePlan(
      blockedRoute: '$sector primary route',
      alternateRoute: 'Local detour via Murree Road',
      alternatePolyline: polyline,
      timeAddedMinutes: 10,
      response: {
        'status': 'REROUTE_ACTIVE',
        'blocked': '$sector primary route',
        'alternate': 'Murree Road detour',
        'time_added_minutes': 10,
        'message': 'Alternate route activated for $crisisType incident.',
      },
    );
  }
}
