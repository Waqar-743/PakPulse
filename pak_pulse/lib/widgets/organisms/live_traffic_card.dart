import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/road_incident.dart';
import '../../providers.dart';
import '../atoms/mono_text.dart';
import '../pp_chrome.dart';

/// Live road-status card backed by the TomTom Traffic Incidents API.
/// Shows real closures, jams, and accidents near a crisis. An empty result
/// is a genuine answer ("roads clear"), not a failure — TomTom incident
/// coverage for Pakistani cities is sparse.
class LiveTrafficCard extends ConsumerWidget {
  final double lat;
  final double lng;
  final String sectorLabel;

  const LiveTrafficCard({
    super.key,
    required this.lat,
    required this.lng,
    required this.sectorLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(roadIncidentsProvider(LatLngKey(lat, lng)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PPSectionHeader(
          kicker: 'REAL-TIME · TRAFFIC',
          title: 'Live Road Status',
        ),
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
                  const Icon(Icons.traffic,
                      size: 14, color: AppColors.signalBlue),
                  const SizedBox(width: 6),
                  MonoText('TOMTOM · TRAFFIC INCIDENTS',
                      fontSize: 9, color: AppColors.textTertiary),
                  const Spacer(),
                  incidents.maybeWhen(
                    data: (_) => const MonoText('● real data',
                        fontSize: 9, color: AppColors.signalBlue),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              incidents.when(
                loading: () => Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.signalBlue),
                    ),
                    const SizedBox(width: 10),
                    MonoText('Scanning live road network…',
                        fontSize: 11, color: AppColors.textSecondary),
                  ],
                ),
                error: (_, __) => _line(Icons.cloud_off,
                    'Traffic feed unavailable right now.'),
                data: (list) {
                  if (list.isEmpty) {
                    return _line(
                      Icons.check_circle_outline,
                      'No active road incidents reported near $sectorLabel. '
                      'Roads currently clear.',
                      tint: AppColors.low,
                    );
                  }
                  final blockages =
                      list.where((i) => i.isBlockage).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Stat(
                            value: '${list.length}',
                            label: 'INCIDENTS',
                            color: AppColors.high,
                          ),
                          const SizedBox(width: 8),
                          _Stat(
                            value: '$blockages',
                            label: 'ROAD CLOSURES',
                            color: AppColors.critical,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final i in list.take(5)) _IncidentRow(incident: i),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(IconData icon, String text, {Color? tint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: tint ?? AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: tint ?? AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoText(value,
                fontSize: 22, fontWeight: FontWeight.w700, color: color),
            MonoText(label, fontSize: 8, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  final RoadIncident incident;
  const _IncidentRow({required this.incident});

  Color get _tint {
    if (incident.isBlockage) return AppColors.critical;
    if (incident.magnitudeOfDelay >= 3) return AppColors.high;
    return AppColors.moderate;
  }

  IconData get _icon {
    switch (incident.iconCategory) {
      case 1:
        return Icons.car_crash;
      case 6:
        return Icons.traffic;
      case 7:
      case 8:
        return Icons.block;
      case 9:
        return Icons.construction;
      case 11:
        return Icons.water_drop;
      default:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final road = incident.from.isNotEmpty ? incident.from : incident.to;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tint.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 16, color: _tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.categoryLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _tint,
                  ),
                ),
                if (road.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    road,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (incident.delaySeconds != null && incident.delaySeconds! > 0) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MonoText(incident.delayLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _tint),
                MonoText('DELAY',
                    fontSize: 8, color: AppColors.textTertiary),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
