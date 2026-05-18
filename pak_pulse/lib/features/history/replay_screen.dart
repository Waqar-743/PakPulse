import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis.dart';
import '../../data/models/agent_step.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/atoms/severity_chip.dart';

class ReplayScreen extends StatefulWidget {
  final Crisis crisis;
  const ReplayScreen({super.key, required this.crisis});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  double _sliderValue = 1.0;

  int get _visibleSteps =>
      (_sliderValue * widget.crisis.reasoning.length).round();

  List<AgentStep> get _stepsAtTime =>
      widget.crisis.reasoning.take(_visibleSteps).toList();

  @override
  Widget build(BuildContext context) {
    final c = widget.crisis;
    final crisisColor = AgentColors.forCrisis(c.type);
    final steps = _stepsAtTime;

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceElevated,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REPLAY',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(c.title,
                style: AppTypography.labelSmall),
          ],
        ),
      ),
      body: Column(
        children: [
          // Crisis header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceElevated,
            child: Row(
              children: [
                SeverityChip(severity: c.severity),
                const SizedBox(width: 12),
                MonoText('RSI ${c.riskScore}',
                    fontSize: 14, fontWeight: FontWeight.w700),
                const Spacer(),
                MonoText('${c.signalCount} signals',
                    fontSize: 12, color: AppColors.textSecondary),
              ],
            ),
          ),
          // Timeline at scrubber position
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _sliderValue == 0
                  ? const _EmptyState()
                  : ListView.builder(
                      key: ValueKey(_visibleSteps),
                      padding: const EdgeInsets.all(16),
                      itemCount: steps.length,
                      itemBuilder: (_, i) => _ReplayStepCard(
                        step: steps[i],
                        crisisColor: crisisColor,
                      ),
                    ),
            ),
          ),
          // Scrubber
          _Scrubber(
            value: _sliderValue,
            totalSteps: c.reasoning.length,
            visibleSteps: _visibleSteps,
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
        ],
      ),
    );
  }
}

class _ReplayStepCard extends StatelessWidget {
  final AgentStep step;
  final Color crisisColor;
  const _ReplayStepCard({required this.step, required this.crisisColor});

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(step.agentName);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${step.agentName.name.toUpperCase()} AGENT',
                style: AppTypography.headingSmall
                    .copyWith(fontSize: 13, color: color),
              ),
              const Spacer(),
              MonoText('${step.durationMs}ms',
                  fontSize: 10, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 6),
          Text(step.outputSummary, style: AppTypography.bodyMedium),
          const SizedBox(height: 6),
          Text(step.reasoning,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  final double value;
  final int totalSteps;
  final int visibleSteps;
  final ValueChanged<double> onChanged;

  const _Scrubber({
    required this.value,
    required this.totalSteps,
    required this.visibleSteps,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MonoText('TIMELINE SCRUBBER',
                  fontSize: 10, color: AppColors.textTertiary),
              const Spacer(),
              MonoText('$visibleSteps / $totalSteps agents',
                  fontSize: 10, color: AppColors.textSecondary),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppColors.critical,
              inactiveTrackColor: AppColors.borderSubtle,
              thumbColor: AppColors.critical,
              overlayColor: AppColors.critical.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
              divisions: totalSteps > 0 ? totalSteps : 1,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoText('START', fontSize: 9, color: AppColors.textTertiary),
              MonoText('END', fontSize: 9, color: AppColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Drag the scrubber to replay',
              style: TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
