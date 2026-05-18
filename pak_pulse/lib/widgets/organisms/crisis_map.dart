import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/crisis.dart';
import '../../data/services/places_service.dart';
import '../../providers.dart';

/// Live Google Maps view for PakPulse.
///
/// Renders a real interactive [GoogleMap] with:
///  • the traffic layer enabled (real-time congestion),
///  • the camera centred on the user's stored city,
///  • a red semi-transparent polygon over the G-10 crisis sector,
///  • a pulsing red halo at the crisis epicentre,
///  • a green alternate-route polyline,
///  • blue markers for nearby emergency services (Google Places, with a
///    curated fallback when no API key is configured).
///
/// Tapping any marker opens a bottom-sheet detail card.
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

  GoogleMapController? _controller;
  late final AnimationController _pulseCtrl;
  List<EmergencyPlace> _places = const [];
  bool _centeredOnUser = false;

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
    _controller?.dispose();
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
    // A single-crisis map (detail view) frames that crisis; the overview
    // map opens on the user's stored city.
    if (widget.crises.length == 1) {
      return LatLng(widget.crises.first.lat, widget.crises.first.lng);
    }
    final loc = ref.read(userLocationProvider);
    return loc != null ? LatLng(loc.lat, loc.lng) : _g10Center;
  }

  void _maybeCenterOnUser() {
    if (_centeredOnUser) return;
    if (widget.center != null || widget.crises.length == 1) return;
    final loc = ref.read(userLocationProvider);
    if (loc != null && _controller != null) {
      _centeredOnUser = true;
      _controller!.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
    }
  }

  // ── Map layers ──────────────────────────────────────────────────────────────

  double _crisisHue(Crisis c) {
    switch (c.type) {
      case CrisisType.flood:
        return BitmapDescriptor.hueAzure;
      case CrisisType.heatwave:
        return BitmapDescriptor.hueOrange;
      case CrisisType.protest:
        return BitmapDescriptor.hueViolet;
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (var i = 0; i < widget.crises.length; i++) {
      final c = widget.crises[i];
      // The first (most urgent) crisis is the epicentre — always red.
      final hue = i == 0 ? BitmapDescriptor.hueRed : _crisisHue(c);
      markers.add(
        Marker(
          markerId: MarkerId('crisis_${c.id}'),
          position: LatLng(c.lat, c.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: c.title, snippet: c.sector),
          onTap: () {
            if (widget.onMarkerTap != null) {
              widget.onMarkerTap!(c);
            } else {
              _showCrisisSheet(c);
            }
          },
        ),
      );
    }

    for (var i = 0; i < _places.length; i++) {
      final p = _places[i];
      markers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(p.lat, p.lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: p.name, snippet: p.type),
          onTap: () => _showPlaceSheet(p),
        ),
      );
    }
    return markers;
  }

  Set<Polygon> _buildPolygons() => {
        // Red semi-transparent crisis-zone polygon over the G-10 sector.
        Polygon(
          polygonId: const PolygonId('g10_crisis_zone'),
          points: _g10Sector,
          fillColor: AppColors.critical.withOpacity(0.22),
          strokeColor: AppColors.critical.withOpacity(0.8),
          strokeWidth: 2,
        ),
      };

  Set<Polyline> _buildPolylines() => {
        // Green recommended alternate route.
        Polyline(
          polylineId: const PolylineId('alternate_route'),
          points: _alternateRoute,
          color: AppColors.low,
          width: 5,
          patterns: [PatternItem.dash(28), PatternItem.gap(14)],
        ),
      };

  Set<Circle> _buildCircles() {
    final circles = <Circle>{};

    // Pulsing red halo at the crisis epicentre.
    final epicentre =
        widget.crises.isNotEmpty ? widget.crises.first : null;
    final epLatLng = epicentre != null
        ? LatLng(epicentre.lat, epicentre.lng)
        : _g10Center;
    final t = _pulseCtrl.value;
    circles.add(
      Circle(
        circleId: const CircleId('epicentre_pulse'),
        center: epLatLng,
        radius: 130 + t * 280,
        fillColor: AppColors.critical.withOpacity((1 - t) * 0.30),
        strokeColor: AppColors.critical.withOpacity((1 - t) * 0.9),
        strokeWidth: 2,
      ),
    );

    // Static affected-radius rings.
    if (widget.showRadius) {
      for (final c in widget.crises) {
        circles.add(
          Circle(
            circleId: CircleId('radius_${c.id}'),
            center: LatLng(c.lat, c.lng),
            radius: c.affectedRadiusMeters.toDouble(),
            fillColor: AgentColors.forCrisis(c.type).withOpacity(0.08),
            strokeColor: AgentColors.forCrisis(c.type).withOpacity(0.35),
            strokeWidth: 1,
          ),
        );
      }
    }
    return circles;
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

    return GoogleMap(
      initialCameraPosition:
          CameraPosition(target: _initialTarget, zoom: widget.zoom),
      // Real-time congestion overlay.
      trafficEnabled: true,
      mapType: MapType.normal,
      compassEnabled: true,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      markers: _buildMarkers(),
      polygons: _buildPolygons(),
      polylines: _buildPolylines(),
      circles: _buildCircles(),
      // Let the map win pinch / pan gestures even inside a scroll view.
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onMapCreated: (c) {
        _controller = c;
        _maybeCenterOnUser();
      },
    );
  }
}
