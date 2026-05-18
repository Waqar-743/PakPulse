import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis.dart';
import '../atoms/severity_chip.dart';
import '../atoms/live_timestamp.dart';
import '../atoms/mono_text.dart';

class CrisisCard extends StatefulWidget {
  final Crisis crisis;
  final VoidCallback? onTap;

  const CrisisCard({super.key, required this.crisis, this.onTap});

  @override
  State<CrisisCard> createState() => _CrisisCardState();
}

class _CrisisCardState extends State<CrisisCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _glowCtrl;
  Animation<double>? _glowAnim;

  @override
  void initState() {
    super.initState();
    if (widget.crisis.severity == SeverityLevel.critical) {
      _glowCtrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
      _glowAnim = Tween<double>(begin: 0.15, end: 0.35).animate(
        CurvedAnimation(parent: _glowCtrl!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _glowCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crisisColor = AgentColors.forCrisis(widget.crisis.type);

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 240,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: crisisColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeverityChip(severity: widget.crisis.severity),
                        const Spacer(),
                        _RsiCounter(rsi: widget.crisis.riskScore),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.crisis.title,
                      style: AppTypography.headingSmall.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.crisis.sector,
                      style: AppTypography.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text('DETECTED ',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: AppColors.textTertiary)),
                        LiveTimestamp(
                          timestamp: widget.crisis.detectedAt,
                          fontSize: 9,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_glowAnim != null) {
      return AnimatedBuilder(
        animation: _glowAnim!,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.critical.withOpacity(_glowAnim!.value),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
        child: card,
      );
    }

    return card;
  }
}

class _RsiCounter extends StatelessWidget {
  final int rsi;
  const _RsiCounter({required this.rsi});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: rsi),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (_, value, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          MonoText(
            '$value',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _rsiColor(value),
          ),
          MonoText(' RSI', fontSize: 8, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Color _rsiColor(int v) {
    if (v >= 80) return AppColors.critical;
    if (v >= 60) return AppColors.high;
    if (v >= 40) return AppColors.moderate;
    return AppColors.low;
  }
}
