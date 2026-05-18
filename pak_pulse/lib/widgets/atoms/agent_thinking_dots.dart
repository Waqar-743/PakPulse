import 'package:flutter/material.dart';

class AgentThinkingDots extends StatefulWidget {
  final Color color;
  final double dotSize;

  const AgentThinkingDots({
    super.key,
    required this.color,
    this.dotSize = 6,
  });

  @override
  State<AgentThinkingDots> createState() => _AgentThinkingDotsState();
}

class _AgentThinkingDotsState extends State<AgentThinkingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (_) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      }),
    );
  }
}
