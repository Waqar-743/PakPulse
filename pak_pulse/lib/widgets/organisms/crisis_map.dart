import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// `hide Path` — latlong2 exports a Path class that collides with dart:ui.Path
// used by the marker CustomPainter below.
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crisis.dart';
import '../../data/services/places_service.dart';
import '../../providers.dart';

/// Interactive OpenStreetMap view for PAK·PULSE (via `flutter_map`).
///
/// Renders a real, no-API-key map with:
///  • OSM raster tiles (CartoDB Voyager light theme),
///  • the camera centred on the user's stored city,
///  • a red semi-transparent polygon over the active crisis sector,
///  • a pulsing red halo at the crisis epicentre,
///  • a green recommended alternate-route polyline,
///  • blue markers for nearby emergency services,
///  • pinch-zoom, pan, and tap-for-detail bottom sheets.
class CrisisMap extends ConsumerStatefulWidget {
  final List<Crisis> crises;
  final void Function(Crisis)? onMarkerTap;
  final LatLng? center;
  final double zoom;
  final bool showRadius;

  const CrisisMap({
    super.key,
    required this.crises,
    this.onMarkerTap,
    this.center,
    this.zoom = 12,
    this.showRadius = true,
  });

  @override
  ConsumerState<CrisisMap> createState() => _CrisisMapState();
}

class _CrisisMapState extends ConsumerState<CrisisMap>
    with SingleTickerProviderStateMixin {
  // ── Pakistan heatmap cities (shown when no active crises) ─────────────────
  static const List<(String, double, double)> _heatCities = [
    ('Islamabad',  33.6844, 73.0479),
    ('Lahore',     31.5204, 74.3587),
    ('Karachi',    24.8607, 67.0011),
    ('Peshawar',   34.0151, 71.5249),
    ('Quetta',     30.1798, 66.9750),
    ('Multan',     30.1575, 71.5249),
    ('Jacobabad',  28.2769, 68.4511),
    ('Faisalabad', 31.4188, 73.0791),
    ('Hyderabad',  25.3960, 68.3578),
  ];

  // ── Demo crisis sector — G-10, Islamabad ───────────────────────────────────
  static const LatLng _g10Center = LatLng(33.6900, 73.0228);

  static const List<LatLng> _g10Sector = [
    LatLng(33.6948, 73.0172),
    LatLng(33.6948, 73.0284),
    LatLng(33.6852, 73.0284),
    LatLng(33.6852, 73.0172),
  ];

  // Recommended alternate route skirting the flooded sector.
  static const List<LatLng> _alternateRoute = [
    LatLng(33.6852, 73.0172),
    LatLng(33.6838, 73.0230),
    LatLng(33.6862, 73.0312),
    LatLng(33.6930, 73.0356),
    LatLng(33.6985, 73.0392),
  ];

  final MapController _controller = MapController();
  late final AnimationController _pulseCtrl;
  List<EmergencyPlace> _places = const [];
  bool _centeredOnUser = false;

  String get _tileUrl {
    final raw = dotenv.maybeGet('MAP_TILE_URL') ??
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    // flutter_map only honours {r} with retinaMode; strip it for a plain URL.
    return raw.replaceAll('{r}', '');
  }

  List<String> get _tileSubdomains {
    final raw = dotenv.maybeGet('MAP_TILE_SUBDOMAINS') ?? 'a,b,c,d';
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _pulseCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPlaces();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final loc = ref.read(userLocationProvider);
    final places = await PlacesService.nearbyEmergencyServices(
      lat: loc?.lat ?? _g10Center.latitude,
      lng: loc?.lng ?? _g10Center.longitude,
    );
    if (mounted) setState(() => _places = places);
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  LatLng get _initialTarget {
    if (widget.center != null) return widget.center!;
    if (widget.crises.isEmpty) {
      // No active crises — zoom out to show all of Pakistan for the heatmap.
      return const LatLng(30.3753, 69.3451);
    }
    if (widget.crises.length == 1) {
      return LatLng(widget.crises.first.lat, widget.crises.first.lng);
    }
    final loc = ref.read(userLocationProvider);
    return loc != null ? LatLng(loc.lat, loc.lng) : _g10Center;
  }

  double get _initialZoom {
    if (widget.crises.isEmpty) return 5.0;
    return widget.zoom;
  }

  void _maybeCenterOnUser() {
    if (_centeredOnUser) return;
    if (widget.center != null || widget.crises.length == 1) return;
    final loc = ref.read(userLocationProvider);
    if (loc != null) {
      _centeredOnUser = true;
      _controller.move(LatLng(loc.lat, loc.lng), widget.zoom);
    }
  }

  // ── Map layers ──────────────────────────────────────────────────────────────

  Polygon get _crisisZonePolygon => Polygon(
        points: _g10Sector,
        isFilled: true,
        color: AppColors.critical.withOpacity(0.22),
        borderColor: AppColors.critical.withOpacity(0.8),
        borderStrokeWidth: 2,
      );

  Polyline get _alternateRoutePolyline => Polyline(
        points: _alternateRoute,
        color: AppColors.low,
        strokeWidth: 5,
      );

  /// Returns a temperature-to-colour mapping used by the heatmap.
  static Color _tempColor(double tempC) {
    if (tempC >= 48) return const Color(0xFFCC0000);   // extreme — dark red
    if (tempC >= 44) return AppColors.critical;          // critical — red
    if (tempC >= 40) return AppColors.heatOrange;        // high — orange
    if (tempC >= 36) return AppColors.high;              // elevated — amber
    if (tempC >= 30) return AppColors.moderate;          // moderate — yellow
    if (tempC >= 24) return AppColors.low;               // normal — green
    return AppColors.signalBlue;                         // cool — blue
  }

  List<CircleMarker> _buildCircles() {
    final circles = <CircleMarker>[];

    if (widget.crises.isEmpty) {
      // ── Heatmap mode — temperature bubbles over Pakistan cities ─────────
      for (final city in _heatCities) {
        final key = LatLngKey(city.$2, city.$3);
        final async = ref.watch(liveConditionsProvider(key));
        async.whenData((cond) {
          if (cond == null) return;
          final color = _tempColor(cond.temperatureC);
          circles.add(CircleMarker(
            point: LatLng(city.$2, city.$3),
            radius: 60000, // 60 km radius bubble
            useRadiusInMeter: true,
            color: color.withOpacity(0.28),
            borderColor: color.withOpacity(0.70),
            borderStrokeWidth: 2,
          ));
        });
        // Show a placeholder bubble while loading
        if (async.isLoading) {
          circles.add(CircleMarker(
            point: LatLng(city.$2, city.$3),
            radius: 60000,
            useRadiusInMeter: true,
            color: AppColors.borderSubtle.withOpacity(0.20),
            borderColor: AppColors.borderSubtle.withOpacity(0.50),
            borderStrokeWidth: 1,
          ));
        }
      }
      return circles;
    }

    // ── Crisis mode — pulsing halo + affected-radius rings ────────────────
    final epicentre = widget.crises.first;
    final epLatLng = LatLng(epicentre.lat, epicentre.lng);
    final t = _pulseCtrl.value;
    circles.add(
      CircleMarker(
        point: epLatLng,
        radius: 130 + t * 280,
        useRadiusInMeter: true,
        color: AppColors.critical.withOpacity((1 - t) * 0.30),
        borderColor: AppColors.critical.withOpacity((1 - t) * 0.9),
        borderStrokeWidth: 2,
      ),
    );

    if (widget.showRadius) {
      for (final c in widget.crises) {
        circles.add(
          CircleMarker(
            point: LatLng(c.lat, c.lng),
            radius: c.affectedRadiusMeters.toDouble(),
            useRadiusInMeter: true,
            color: AgentColors.forCrisis(c.type).withOpacity(0.08),
            borderColor: AgentColors.forCrisis(c.type).withOpacity(0.35),
            borderStrokeWidth: 1,
          ),
        );
      }
    }
    return circles;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (widget.crises.isEmpty) {
      // ── Heatmap city labels ──────────────────────────────────────────────
      for (final city in _heatCities) {
        final key = LatLngKey(city.$2, city.$3);
        final async = ref.watch(liveConditionsProvider(key));
        final tempStr = async.whenOrNull(
              data: (c) => c != null ? '${c.temperatureC.round()}°' : null,
            ) ?? '…';
        final color = async.whenOrNull(
              data: (c) => c != null ? _tempColor(c.temperatureC) : AppColors.textTertiary,
            ) ?? AppColors.textTertiary;
        markers.add(Marker(
          point: LatLng(city.$2, city.$3),
          width: 80,
          height: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  '${city.$1}\n$tempStr',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      return markers;
    }

    for (var i = 0; i < widget.crises.length; i++) {
      final c = widget.crises[i];
      // The first (most urgent) crisis is the epicentre — always red.
      final color =
          i == 0 ? AppColors.critical : AgentColors.forCrisis(c.type);
      markers.add(
        Marker(
          point: LatLng(c.lat, c.lng),
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              if (widget.onMarkerTap != null) {
                widget.onMarkerTap!(c);
              } else {
                _showCrisisSheet(c);
              }
            },
            child: _MapPin(color: color, icon: _iconFor(c.type)),
          ),
        ),
      );
    }

    for (var i = 0; i < _places.length; i++) {
      final p = _places[i];
      markers.add(
        Marker(
          point: LatLng(p.lat, p.lng),
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () => _showPlaceSheet(p),
            child: _ServiceDot(),
          ),
        ),
      );
    }
    return markers;
  }

  IconData _iconFor(CrisisType type) {
    switch (type) {
      case CrisisType.flood:
        return Icons.water_drop;
      case CrisisType.heatwave:
        return Icons.local_fire_department;
      case CrisisType.protest:
        return Icons.groups;
    }
  }

  // ── Detail bottom sheets ────────────────────────────────────────────────────

  void _showCrisisSheet(Crisis c) {
    _showSheet(
      accent: AgentColors.forCrisis(c.type),
      eyebrow: c.type.label.toUpperCase(),
      title: c.title,
      lines: [
        ('Sector', c.sector),
        ('Severity', c.severity.label),
        ('Risk score', '${c.riskScore} / 100'),
        ('Radius', '${c.affectedRadiusMeters} m'),
      ],
    );
  }

  void _showPlaceSheet(EmergencyPlace p) {
    _showSheet(
      accent: AppColors.signalBlue,
      eyebrow: 'EMERGENCY SERVICE',
      title: p.name,
      lines: [
        ('Type', p.type),
        ('Coordinates',
            '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}'),
      ],
    );
  }

  void _showSheet({
    required Color accent,
    required String eyebrow,
    required String title,
    required List<(String, String)> lines,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                eyebrow,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.$1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      l.$2,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Re-centre once the stored location resolves (overview map only).
    ref.listen(userLocationProvider, (_, __) => _maybeCenterOnUser());

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _initialTarget,
        initialZoom: _initialZoom,
        minZoom: 4,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          subdomains: _tileSubdomains,
          userAgentPackageName: 'com.pakpulse.app',
          maxZoom: 19,
        ),
        if (widget.crises.isNotEmpty) ...[
          PolygonLayer(polygons: [_crisisZonePolygon]),
          PolylineLayer(polylines: [_alternateRoutePolyline]),
        ],
        CircleLayer(circles: _buildCircles()),
        MarkerLayer(markers: _buildMarkers()),
        // OSM attribution — required by the tile provider's usage policy.
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

// ── Marker widgets ────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        // Little pointer triangle.
        CustomPaint(
          size: const Size(12, 8),
          painter: _PinTailPainter(color),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

class _ServiceDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.signalBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.signalBlue.withOpacity(0.5),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Icon(Icons.local_hospital, color: Colors.white, size: 14),
    );
  }
}
