import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A continuously revolving 3D globe rendered entirely with a [CustomPainter].
///
/// Every point is projected from a real unit sphere (latitude/longitude →
/// orthographic screen space with an axial tilt), so meridians sweep with
/// genuine depth and the far hemisphere is occluded by the planet body.
///
/// Brand-matched to PAK·PULSE: deep ops-console navy ocean, a crimson "pulse"
/// signal grid, expanding pulse rings echoing the launcher mark, an atmosphere
/// rim glow, and a live marker breathing over Islamabad.
class RotatingGlobe extends StatefulWidget {
  const RotatingGlobe({super.key, this.size = 220});

  final double size;

  @override
  State<RotatingGlobe> createState() => _RotatingGlobeState();
}

class _RotatingGlobeState extends State<RotatingGlobe>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_spin, _pulse]),
          builder: (_, __) => CustomPaint(
            painter: _GlobePainter(
              spin: _spin.value * 2 * math.pi,
              pulse: _pulse.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({required this.spin, required this.pulse});

  /// Rotation about the polar axis, in radians.
  final double spin;

  /// 0→1 looping value driving pulse rings and the live marker.
  final double pulse;

  /// Axial tilt toward the viewer (north pole leans in).
  static const double _tilt = -0.42;

  /// Light direction (x→right, y→up, z→toward viewer), normalised.
  static final List<double> _light = _normalise(-0.52, 0.46, 0.74);

  static List<double> _normalise(double x, double y, double z) {
    final m = math.sqrt(x * x + y * y + z * z);
    return [x / m, y / m, z / m];
  }

  /// Projects a sphere coordinate to screen space.
  ///
  /// Returns `[screenX, screenY, depth, normalX, normalY, normalZ]` where
  /// `depth > 0` means the point faces the viewer.
  List<double> _project(double lat, double lon, Offset c, double r) {
    final cosLat = math.cos(lat), sinLat = math.sin(lat);
    final lambda = lon + spin;
    final x = cosLat * math.sin(lambda);
    final y = sinLat;
    final z = cosLat * math.cos(lambda);
    // Tilt about the X axis.
    final ct = math.cos(_tilt), st = math.sin(_tilt);
    final y2 = y * ct - z * st;
    final z2 = y * st + z * ct;
    return [c.dx + x * r, c.dy - y2 * r, z2, x, y2, z2];
  }

  double _lightAt(double nx, double ny, double nz) {
    final d = nx * _light[0] + ny * _light[1] + nz * _light[2];
    return (d * 0.5 + 0.5).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.345;
    final red = AppColors.critical;

    // 1 ── Expanding brand pulse rings (echo of the launcher mark).
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      final phase = (pulse + i / 3) % 1.0;
      final radius = r * (1.03 + phase * 0.62);
      final opacity = ((1.0 - phase) * 0.36).clamp(0.0, 1.0);
      canvas.drawCircle(c, radius, ringPaint..color = red.withOpacity(opacity));
    }

    // 2 ── Atmosphere glow.
    canvas.drawCircle(
      c,
      r * 1.34,
      Paint()
        ..shader = RadialGradient(
          colors: [
            red.withOpacity(0.0),
            red.withOpacity(0.17),
            red.withOpacity(0.0),
          ],
          stops: const [0.60, 0.81, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.34)),
    );

    // 3 ── Planet body — navy ocean lit from the top-left.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.42, -0.46),
          radius: 1.25,
          colors: [
            Color(0xFF26446F),
            Color(0xFF13284A),
            Color(0xFF05080F),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Constrain surface detail to the planet disc.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
    );

    // 4 ── Surface dot stipple (even density per latitude band).
    final dotPaint = Paint();
    for (var latDeg = -78; latDeg <= 78; latDeg += 12) {
      final lat = latDeg * math.pi / 180;
      final count = (34 * math.cos(lat)).round().clamp(5, 34);
      for (var k = 0; k < count; k++) {
        final lon = 2 * math.pi * k / count;
        final p = _project(lat, lon, c, r);
        if (p[2] <= 0.02) continue;
        final light = _lightAt(p[3], p[4], p[5]);
        final opacity =
            ((0.16 + light * 0.62) * (0.34 + p[2] * 0.66)).clamp(0.0, 1.0);
        dotPaint.color = const Color(0xFFBFD3EE).withOpacity(opacity);
        canvas.drawCircle(Offset(p[0], p[1]), 0.9 + p[2] * 1.05, dotPaint);
      }
    }

    // 5 ── Meridians + parallels (the revolving signal grid).
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (var m = 0; m < 12; m++) {
      _drawMeridian(canvas, gridPaint, red, c, r,
          lon: 2 * math.pi * m / 12, boost: m == 0 ? 1.7 : 1.0);
    }
    for (final latDeg in const [-60, -30, 0, 30, 60]) {
      _drawParallel(canvas, gridPaint, red, c, r,
          lat: latDeg.toDouble(), boost: latDeg == 0 ? 1.7 : 1.0);
    }

    // 6 ── City signal nodes across Pakistan.
    const cities = [
      [24.9, 67.0], // Karachi
      [31.5, 74.3], // Lahore
      [34.0, 71.5], // Peshawar
      [30.2, 67.0], // Quetta
      [25.4, 68.4], // Hyderabad
    ];
    for (final city in cities) {
      final p = _project(
          city[0] * math.pi / 180, city[1] * math.pi / 180, c, r);
      if (p[2] <= 0.05) continue;
      final glow = 0.34 + p[2] * 0.66;
      canvas.drawCircle(Offset(p[0], p[1]), 3.4,
          Paint()..color = AppColors.signalBlue.withOpacity(0.18 * glow));
      canvas.drawCircle(Offset(p[0], p[1]), 1.5,
          Paint()..color = AppColors.signalBlue.withOpacity(0.95 * glow));
    }

    // 7 ── Live marker over Islamabad — breathing pulse.
    final capital = _project(
        33.7 * math.pi / 180, 73.0 * math.pi / 180, c, r);
    if (capital[2] > 0.05) {
      final cp = Offset(capital[0], capital[1]);
      final depth = capital[2];
      canvas.drawCircle(
        cp,
        4 + pulse * 13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = red.withOpacity((1 - pulse) * 0.7 * depth),
      );
      canvas.drawCircle(cp, 7, Paint()..color = red.withOpacity(0.30 * depth));
      canvas.drawCircle(cp, 3.1, Paint()..color = red.withOpacity(depth));
      canvas.drawCircle(
          cp, 1.3, Paint()..color = Colors.white.withOpacity(depth));
    }

    // 8 ── Unlit limb — soft terminator on the lower-right.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.5, 0.55),
          radius: 1.15,
          colors: [
            Colors.black.withOpacity(0.0),
            Colors.black.withOpacity(0.0),
            Colors.black.withOpacity(0.55),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    canvas.restore();

    // 9 ── Rim highlight catching the light on the upper-left edge.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.95,
      math.pi * 0.62,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.24),
    );
  }

  void _drawMeridian(Canvas canvas, Paint paint, Color color, Offset c,
      double r, {required double lon, required double boost}) {
    List<double>? prev;
    for (var d = -82.0; d <= 82.01; d += 6) {
      final p = _project(d * math.pi / 180, lon, c, r);
      if (prev != null) _segment(canvas, paint, color, prev, p, boost);
      prev = p;
    }
  }

  void _drawParallel(Canvas canvas, Paint paint, Color color, Offset c,
      double r, {required double lat, required double boost}) {
    final latR = lat * math.pi / 180;
    List<double>? prev;
    for (var d = 0.0; d <= 360.01; d += 9) {
      final p = _project(latR, d * math.pi / 180, c, r);
      if (prev != null) _segment(canvas, paint, color, prev, p, boost);
      prev = p;
    }
  }

  void _segment(Canvas canvas, Paint paint, Color color, List<double> a,
      List<double> b, double boost) {
    if (a[2] <= 0 && b[2] <= 0) return;
    final depth = ((a[2] + b[2]) / 2).clamp(0.0, 1.0);
    final opacity = ((0.06 + depth * 0.30) * boost).clamp(0.0, 0.85);
    paint.color = color.withOpacity(opacity);
    canvas.drawLine(Offset(a[0], a[1]), Offset(b[0], b[1]), paint);
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.spin != spin || old.pulse != pulse;
}
