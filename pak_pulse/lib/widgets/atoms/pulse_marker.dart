import 'package:flutter/material.dart';

class PulseMarker extends StatefulWidget {
  final Color color;
  final double size;
  final double speed; // 1.0 = critical, 1.6 = high, 2.4 = moderate

  const PulseMarker({
    super.key,
    required this.color,
    this.size = 12,
    this.speed = 1.6,
  });

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (widget.speed * 1000).round()),
      );
    });

    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 0.5, end: 2.5).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();

    _fadeAnims = _controllers
        .map((c) => Tween<double>(begin: 0.7, end: 0.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () {
        if (mounted) _controllers[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 5,
        height: widget.size * 5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              ScaleTransition(
                scale: _scaleAnims[i],
                child: FadeTransition(
                  opacity: _fadeAnims[i],
                  child: Container(
                    width: widget.size * 2,
                    height: widget.size * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color, width: 1.5),
                    ),
                  ),
                ),
              ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
