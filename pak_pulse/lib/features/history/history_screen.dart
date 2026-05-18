import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/crisis.dart';
import '../../providers.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/atoms/severity_chip.dart';
import '../../widgets/pp_chrome.dart';
import 'replay_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historical = ref.watch(historicalCrisesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                _HistoryHeader(
                  total: historical.length,
                  onBack: () =>
                      Navigator.of(context).maybePop(),
                ),
                // ── List ────────────────────────────────────
                Expanded(
                  child: historical.isEmpty
                      ? Center(
                          child: MonoText(
                            'No resolved events',
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: historical.length,
                          itemBuilder: (_, i) =>
                              _HistoryCard(
                            crisis: historical[i],
                            index: i,
                            onReplay: () =>
                                Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReplayScreen(
                                    crisis: historical[i]),
                              ),
                            ),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _HistoryHeader extends StatelessWidget {
  final int total;
  final VoidCallback onBack;

  const _HistoryHeader(
      {required this.total, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
            bottom:
                BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 18),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PPEyebrow('RESOLVED EVENTS'),
                const SizedBox(height: 2),
                Text(
                  'Operations History',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.low.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.low.withOpacity(0.3)),
            ),
            child: MonoText(
              '$total TOTAL',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.low,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Crisis crisis;
  final VoidCallback onReplay;
  final int index;

  const _HistoryCard({
    required this.crisis,
    required this.onReplay,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final crisisColor = AgentColors.forCrisis(crisis.type);
    final duration = crisis.reasoning.isNotEmpty
        ? '${crisis.reasoning.fold<int>(0, (a, s) => a + s.durationMs) ~/ 1000}s'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Left colored border strip + content
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left color strip
                Container(
                  width: 4,
                  color: crisisColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon badge
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: crisisColor
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                              ),
                              child: Icon(
                                _crisisIcon(crisis.type),
                                size: 16,
                                color: crisisColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    crisis.title,
                                    style: GoogleFonts
                                        .plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: AppColors
                                          .textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      MonoText(
                                        crisis.sector,
                                        fontSize: 9,
                                        color: AppColors
                                            .textSecondary,
                                      ),
                                      const SizedBox(
                                          width: 8),
                                      MonoText(
                                        AppDateUtils
                                            .formatDate(
                                                crisis
                                                    .detectedAt),
                                        fontSize: 9,
                                        color: AppColors
                                            .textTertiary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // RSI score
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                MonoText(
                                  '${crisis.riskScore}',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _rsiColor(
                                      crisis.riskScore),
                                ),
                                MonoText(
                                  'RSI',
                                  fontSize: 8,
                                  color:
                                      AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SeverityChip(
                                severity: crisis.severity),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.low
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.low
                                        .withOpacity(0.3)),
                              ),
                              child: MonoText(
                                'RESOLVED',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.low,
                              ),
                            ),
                            const Spacer(),
                            MonoText(
                              'PIPELINE: $duration',
                              fontSize: 9,
                              color: AppColors.textTertiary,
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
          // Stat row
          Container(
            padding: const EdgeInsets.fromLTRB(
                18, 8, 18, 8),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                _MiniStat(
                    label: 'SIGNALS',
                    value: '${crisis.signalCount}'),
                _MiniStat(
                    label: 'PEAK RSI',
                    value: '${crisis.riskScore}'),
                _MiniStat(
                    label: 'DURATION', value: duration),
                _MiniStat(
                    label: 'TYPE',
                    value: crisis.type.label
                        .toUpperCase()
                        .split(' ')
                        .first),
              ],
            ),
          ),
          // Replay button
          Padding(
            padding:
                const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReplay,
                icon: const Icon(Icons.replay, size: 14),
                label: Text(
                  'REPLAY PIPELINE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: crisisColor,
                  side: BorderSide(
                      color: crisisColor.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30)),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(
            delay: Duration(milliseconds: 60 * index))
        .fadeIn(
          duration: 600.ms,
          curve: Cubic(0.32, 0.72, 0, 1),
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 600.ms,
          curve: Cubic(0.32, 0.72, 0, 1),
        );
  }

  Color _rsiColor(int v) {
    if (v >= 80) return AppColors.critical;
    if (v >= 60) return AppColors.high;
    if (v >= 40) return AppColors.moderate;
    return AppColors.low;
  }

  IconData _crisisIcon(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'flood':
        return Icons.water;
      case 'heatwave':
        return Icons.whatshot;
      case 'protest':
        return Icons.warning_amber_outlined;
      default:
        return Icons.crisis_alert;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          MonoText(
            value,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          MonoText(
            label,
            fontSize: 8,
            color: AppColors.textTertiary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
