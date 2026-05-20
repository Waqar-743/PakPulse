import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/notification_service.dart';

/// Renders the most recent unread verified-crisis alert near the user as a
/// dismissible banner. The full history lives in the notifications panel
/// (accessed via the bell icon in the app chrome).
class NotificationBanner extends ConsumerWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notificationStoreProvider);
    final unread = all.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return const SizedBox.shrink();

    final n = unread.first;
    final color = AgentColors.forCrisis(n.crisis.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Text(n.crisis.type.emoji,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VERIFIED · ${n.crisis.type.label}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${n.crisis.sector} — ${n.distanceKm.toStringAsFixed(1)} km from you',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  n.crisis.summaryEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Email this alert',
            icon: const Icon(Icons.mail_outline, size: 20),
            onPressed: () => _shareViaEmail(n),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref
                .read(notificationStoreProvider.notifier)
                .markRead(n.id),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.2, end: 0);
  }

  Future<void> _shareViaEmail(CrisisNotification n) async {
    final subject =
        'PAK·PULSE Alert: ${n.crisis.type.label} verified near ${n.crisis.sector}';
    final body = '''
A new verified crisis has been detected near you.

Type:        ${n.crisis.type.label}
Sector:      ${n.crisis.sector}
Severity:    ${n.crisis.severity.label}
Distance:    ${n.distanceKm.toStringAsFixed(1)} km from your location
Confidence:  ${(n.crisis.confidence * 100).toStringAsFixed(0)}%
Detected:    ${n.crisis.detectedAt.toIso8601String()}

Summary:
${n.crisis.summaryEn}

— Sent from PAK·PULSE
''';

    final uri = Uri(
      scheme: 'mailto',
      query: _encodeQuery({'subject': subject, 'body': body}),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
