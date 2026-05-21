import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/disaster_news.dart';
import '../../providers.dart';
import '../atoms/mono_text.dart';

/// Live regional disaster feed, sourced from GDACS (free, no API key).
/// Surfaces real floods and hazards near Pakistan as an external signal
/// source feeding the crisis-intelligence picture.
class DisasterFeedCard extends ConsumerWidget {
  const DisasterFeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(disasterFeedProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, size: 14, color: AppColors.signalBlue),
              const SizedBox(width: 6),
              MonoText('GDACS · LIVE FEED',
                  fontSize: 9, color: AppColors.textTertiary),
              const Spacer(),
              feed.maybeWhen(
                data: (_) => const MonoText('● real data',
                    fontSize: 9, color: AppColors.signalBlue),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          feed.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.signalBlue),
                  ),
                  const SizedBox(width: 10),
                  MonoText('Fetching live disaster feed…',
                      fontSize: 11, color: AppColors.textSecondary),
                ],
              ),
            ),
            error: (_, __) => _message(
                Icons.cloud_off, 'Disaster feed unavailable right now.'),
            data: (events) {
              if (events.isEmpty) {
                return _message(Icons.check_circle_outline,
                    'No active regional disasters reported.');
              }
              return Column(
                children: [
                  for (final e in events) _DisasterRow(event: e),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class _DisasterRow extends StatelessWidget {
  final DisasterNews event;
  const _DisasterRow({required this.event});

  Color get _alertColor {
    switch (event.alertLevel.toLowerCase()) {
      case 'red':
        return AppColors.critical;
      case 'orange':
        return AppColors.high;
      default:
        return AppColors.low;
    }
  }

  IconData get _icon {
    switch (event.eventType) {
      case 'FL':
        return Icons.water_drop;
      case 'EQ':
        return Icons.vibration;
      case 'WF':
        return Icons.local_fire_department;
      case 'DR':
        return Icons.wb_sunny;
      case 'TC':
        return Icons.cyclone;
      default:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: event.isPakistan
              ? AppColors.signalBlue.withOpacity(0.4)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _alertColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, size: 16, color: _alertColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (event.isPakistan) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.signalBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const MonoText('PK',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.signalBlue),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    MonoText(
                      '${event.typeLabel.toUpperCase()} · ${event.alertLevel.toUpperCase()}',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _alertColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MonoText(
                        event.country,
                        fontSize: 9,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
