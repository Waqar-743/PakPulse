import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/constants/agent_colors.dart';

class SeverityChip extends StatelessWidget {
  final SeverityLevel severity;

  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forSeverity(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        severity.label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
