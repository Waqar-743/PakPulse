import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis.dart';
import '../../data/models/live_conditions.dart';
import '../../providers.dart';
import '../../widgets/atoms/live_timestamp.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/atoms/severity_chip.dart';
import '../../widgets/molecules/action_card.dart';
import '../../widgets/organisms/agent_timeline.dart';
import '../../widgets/organisms/crisis_map.dart';
import '../../widgets/pp_chrome.dart';

class CrisisDetailScreen extends ConsumerWidget {
  final String crisisId;
  const CrisisDetailScreen({super.key, required this.crisisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crisis = ref.watch(crisisByIdProvider(crisisId));
    if (crisis == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBase,
        appBar: AppBar(title: const Text('Crisis Not Found')),
        body: const Center(child: Text('Crisis not found')),
      );
    }
    return _CrisisDetailView(crisis: crisis);
  }
}

class _CrisisDetailView extends StatefulWidget {
  final Crisis crisis;
  const _CrisisDetailView({required this.crisis});

  @override
  State<_CrisisDetailView> createState() => _CrisisDetailViewState();
}

class _CrisisDetailViewState extends State<_CrisisDetailView>
    with SingleTickerProviderStateMixin {
  // Keep TabController for backward compat (not used for tabs anymore but
  // referenced by original logic for dispose safety)
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.crisis;
    final crisisColor = AgentColors.forCrisis(c.type);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // ── Back + event ID nav ──────────────────────────────────────
                _NavRow(crisis: c, crisisColor: crisisColor),
                // ── Scrollable content ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section
                        _HeaderSection(crisis: c, crisisColor: crisisColor)
                            .animate(delay: 50.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            )
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // Map panel
                        _MapPanel(crisis: c)
                            .animate(delay: 100.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // Telemetry data rows
                        _TelemetryCard(crisis: c)
                            .animate(delay: 150.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // Live conditions
                        _LiveConditionsCard(crisis: c)
                            .animate(delay: 180.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // Summary section
                        _SummarySection(crisis: c, crisisColor: crisisColor)
                            .animate(delay: 200.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // Actions section
                        _ActionsSection(crisis: c)
                            .animate(delay: 250.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // CTA row
                        _CtaRow(crisis: c)
                            .animate(delay: 300.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // Agent reasoning section
                        _AgentReasoningSection(crisis: c)
                            .animate(delay: 350.ms)
                            .fadeIn(
                              duration: 600.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Row ───────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final Crisis crisis;
  final Color crisisColor;
  const _NavRow({required this.crisis, required this.crisisColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          PPEyebrow('EVENT · ${crisis.id.toUpperCase()}'),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: crisisColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: crisisColor.withOpacity(0.3)),
            ),
            child: MonoText(
              crisis.type.label.toUpperCase(),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: crisisColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Header Section ─────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final Crisis crisis;
  final Color crisisColor;
  const _HeaderSection(
      {required this.crisis, required this.crisisColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPEyebrow(
          crisis.type.label.toUpperCase() + ' · ACTIVE',
          color: crisisColor,
        ),
        const SizedBox(height: 6),
        Text(
          crisis.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            crisis.summaryUr,
            style: GoogleFonts.notoNastaliqUrdu(
              fontSize: 14,
              height: 1.9,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SeverityChip(severity: crisis.severity),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: crisisColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: crisisColor.withOpacity(0.3)),
              ),
              child: MonoText(
                '${(crisis.confidence * 100).round()}% CONF',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: crisisColor,
              ),
            ),
            const SizedBox(width: 8),
            MonoText(
              crisis.sector,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            const Spacer(),
            LiveTimestamp(
                timestamp: crisis.detectedAt, fontSize: 10),
          ],
        ),
      ],
    );
  }
}

// ── Map Panel ─────────────────────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  final Crisis crisis;
  const _MapPanel({required this.crisis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPSectionHeader(kicker: 'SPATIAL · DATA', title: 'Crisis Map'),
        const SizedBox(height: 10),
        PPBezel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(21),
                  topRight: Radius.circular(21),
                ),
                child: SizedBox(
                  height: 220,
                  child: CrisisMap(
                    crises: [crisis],
                    zoom: 14,
                    showRadius: true,
                  ),
                ),
              ),
              // Legend strip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppColors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    _LegendDot(
                        color: AgentColors.forCrisis(crisis.type)),
                    const SizedBox(width: 6),
                    MonoText(
                      crisis.type.label.toUpperCase(),
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                    const Spacer(),
                    Icon(Icons.radio_button_unchecked,
                        size: 10,
                        color: AgentColors.forCrisis(crisis.type)
                            .withOpacity(0.5)),
                    const SizedBox(width: 4),
                    MonoText(
                      '${crisis.affectedRadiusMeters}m RADIUS',
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ── Telemetry Card ────────────────────────────────────────────────────────────

class _TelemetryCard extends StatelessWidget {
  final Crisis crisis;
  const _TelemetryCard({required this.crisis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPSectionHeader(kicker: 'TELEMETRY · DATA', title: 'Event Details'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _DataRow(
                label: 'SOURCE',
                value: crisis.sector,
                accent: AppColors.textPrimary,
              ),
              Divider(
                  height: 1,
                  color: AppColors.borderSubtle),
              _DataRow(
                label: 'RISK SCORE',
                value: '${crisis.riskScore} / 100',
                accent: _rsiColor(crisis.riskScore),
              ),
              Divider(
                  height: 1,
                  color: AppColors.borderSubtle),
              _DataRow(
                label: 'SIGNALS',
                value: '${crisis.signalCount} captured',
                accent: AppColors.signalBlue,
              ),
              Divider(
                  height: 1,
                  color: AppColors.borderSubtle),
              _DataRow(
                label: 'RADIUS',
                value: '${crisis.affectedRadiusMeters}m',
                accent: AgentColors.forCrisis(crisis.type),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _rsiColor(int v) {
    if (v >= 80) return AppColors.critical;
    if (v >= 60) return AppColors.high;
    if (v >= 40) return AppColors.moderate;
    return AppColors.low;
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _DataRow(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          MonoText(label, fontSize: 10, color: AppColors.textTertiary),
          const Spacer(),
          MonoText(value,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent),
        ],
      ),
    );
  }
}

// ── Summary Section ───────────────────────────────────────────────────────────

class _SummarySection extends StatefulWidget {
  final Crisis crisis;
  final Color crisisColor;
  const _SummarySection(
      {required this.crisis, required this.crisisColor});

  @override
  State<_SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends State<_SummarySection> {
  bool _showUrdu = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.crisis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: PPSectionHeader(
                kicker: 'ANALYSIS · SUMMARY',
                title: 'Situation Brief',
              ),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('EN')),
                ButtonSegment(value: true, label: Text('UR')),
              ],
              selected: {_showUrdu},
              onSelectionChanged: (v) =>
                  setState(() => _showUrdu = v.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? widget.crisisColor.withOpacity(0.2)
                        : Colors.transparent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: _showUrdu
              ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    c.summaryUr,
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 15,
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              : Text(c.summaryEn, style: AppTypography.bodyLarge),
        ),
      ],
    );
  }
}

// ── Actions Section ───────────────────────────────────────────────────────────

class _ActionsSection extends StatefulWidget {
  final Crisis crisis;
  const _ActionsSection({required this.crisis});

  @override
  State<_ActionsSection> createState() => _ActionsSectionState();
}

class _ActionsSectionState extends State<_ActionsSection> {
  late List actions;

  @override
  void initState() {
    super.initState();
    actions = widget.crisis.actions;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPSectionHeader(
            kicker: 'RESPONSE · ACTIONS',
            title: 'Action Items'),
        const SizedBox(height: 10),
        if (actions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: MonoText(
                'No actions generated yet',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          )
        else
          ...List.generate(
            actions.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActionCard(
                action: actions[i],
                onExecuted: (updated) {
                  setState(() => actions[i] = updated);
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ── CTA Row ───────────────────────────────────────────────────────────────────

class _CtaRow extends ConsumerWidget {
  final Crisis crisis;
  const _CtaRow({required this.crisis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Switch to the Actions tab in the persistent shell.
              ref.read(navIndexProvider.notifier).state = 2;
              context.go('/home');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              'VIEW ACTIONS',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.push('/trace/${crisis.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              'AGENT TRACE',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Agent Reasoning Section ───────────────────────────────────────────────────

class _AgentReasoningSection extends StatelessWidget {
  final Crisis crisis;
  const _AgentReasoningSection({required this.crisis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPSectionHeader(
            kicker: 'AI · PIPELINE TRACE',
            title: 'Agent Reasoning'),
        const SizedBox(height: 10),
        PPBezel(
          child: crisis.reasoning.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: MonoText(
                    'No reasoning trace available',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                )
              : AgentTimeline(
                  steps: crisis.reasoning,
                  isLoading: crisis.reasoning.isEmpty,
                ),
        ),
      ],
    );
  }
}

// ── Live Conditions Card ──────────────────────────────────────────────────────

class _LiveConditionsCard extends ConsumerWidget {
  final Crisis crisis;
  const _LiveConditionsCard({required this.crisis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConditions = ref.watch(
      liveConditionsProvider(LatLngKey(crisis.lat, crisis.lng)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPSectionHeader(
            kicker: 'REAL-TIME · METEO',
            title: 'Live Conditions'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const MonoText('● real data',
                      fontSize: 9, color: AppColors.signalBlue),
                  const Spacer(),
                  MonoText(
                    asyncConditions.maybeWhen(
                      data: (c) => c?.attribution ?? '—',
                      orElse: () => '—',
                    ),
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              asyncConditions.when(
                loading: () => Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.signalBlue),
                    ),
                    const SizedBox(width: 10),
                    MonoText('Fetching live readings…',
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ],
                ),
                error: (_, __) => Row(
                  children: [
                    Icon(Icons.cloud_off,
                        size: 14,
                        color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                        'Live feed unavailable — using mock baseline',
                        style: AppTypography.bodyMedium),
                  ],
                ),
                data: (data) {
                  if (data == null) {
                    return Row(
                      children: [
                        Icon(Icons.cloud_off,
                            size: 14,
                            color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Text('No live data returned',
                            style: AppTypography.bodyMedium),
                      ],
                    );
                  }
                  return _LiveReadings(
                      crisis: crisis, conditions: data);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveReadings extends StatelessWidget {
  final Crisis crisis;
  final LiveConditions conditions;
  const _LiveReadings(
      {required this.crisis, required this.conditions});

  @override
  Widget build(BuildContext context) {
    final corrob = _corroboration(crisis.type, conditions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ReadingCell(
              icon: Icons.thermostat,
              label: 'TEMP',
              value: '${conditions.temperatureC.toStringAsFixed(1)}°C',
              tint: _tempTint(conditions.temperatureC),
            ),
            _ReadingCell(
              icon: Icons.water_drop_outlined,
              label: 'RAIN 1h',
              value:
                  '${conditions.precipitationMmLastHour.toStringAsFixed(1)} mm',
              tint: _rainTint(
                  conditions.precipitationMmLastHour),
            ),
            _ReadingCell(
              icon: Icons.opacity,
              label: 'HUMIDITY',
              value:
                  '${conditions.humidityPercent.toStringAsFixed(0)}%',
              tint: AppColors.signalBlue,
            ),
            _ReadingCell(
              icon: Icons.cloud_outlined,
              label: 'COND.',
              value: conditions.weatherLabel,
              tint: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: corrob.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: corrob.color.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: corrob.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  corrob.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: corrob.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _Corroboration _corroboration(
      CrisisType type, LiveConditions c) {
    switch (type) {
      case CrisisType.flood:
        if (c.precipitationMmLastHour >= 10) {
          return _Corroboration(
            color: AppColors.low,
            message:
                'Real-time precipitation (${c.precipitationMmLastHour.toStringAsFixed(1)} mm/h) corroborates flood crisis.',
          );
        }
        if (c.precipitationMmLastHour >= 1) {
          return _Corroboration(
            color: AppColors.moderate,
            message:
                'Light precipitation present (${c.precipitationMmLastHour.toStringAsFixed(1)} mm/h). Partial corroboration.',
          );
        }
        return _Corroboration(
          color: AppColors.textTertiary,
          message:
              'No current precipitation. Crisis may be receding or based on prior rainfall.',
        );
      case CrisisType.heatwave:
        if (c.temperatureC >= 45) {
          return _Corroboration(
            color: AppColors.critical,
            message:
                'Live temp ${c.temperatureC.toStringAsFixed(1)}°C confirms extreme heatwave conditions.',
          );
        }
        if (c.temperatureC >= 38) {
          return _Corroboration(
            color: AppColors.high,
            message:
                'Live temp ${c.temperatureC.toStringAsFixed(1)}°C — elevated, supports heatwave designation.',
          );
        }
        return _Corroboration(
          color: AppColors.textTertiary,
          message:
              'Live temp ${c.temperatureC.toStringAsFixed(1)}°C is below heatwave threshold (38°C).',
        );
      case CrisisType.protest:
        return _Corroboration(
          color: AppColors.signalBlue,
          message:
              'Weather not a primary signal for protests. Live readings shown for context only.',
        );
    }
  }

  Color _tempTint(double t) {
    if (t >= 45) return AppColors.critical;
    if (t >= 38) return AppColors.high;
    if (t >= 30) return AppColors.moderate;
    return AppColors.signalBlue;
  }

  Color _rainTint(double mm) {
    if (mm >= 30) return AppColors.critical;
    if (mm >= 10) return AppColors.high;
    if (mm >= 1) return AppColors.moderate;
    return AppColors.textTertiary;
  }
}

class _ReadingCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  const _ReadingCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: tint),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 2),
          MonoText(value,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tint),
        ],
      ),
    );
  }
}

class _Corroboration {
  final Color color;
  final String message;
  const _Corroboration(
      {required this.color, required this.message});
}

// Keep ConfidenceGauge for other uses
// ignore: unused_element
class _ConfidenceGauge extends StatelessWidget {
  final double confidence;
  final Color color;
  const _ConfidenceGauge(
      {required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter: _ArcPainter(value: confidence, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: confidence),
                duration: const Duration(milliseconds: 1200),
                builder: (_, v, __) => MonoText(
                  '${(v * 100).round()}%',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text('CONF', style: AppTypography.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  const _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 8.0;
    final radius = (size.width - strokeWidth) / 2;

    final bg = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}
