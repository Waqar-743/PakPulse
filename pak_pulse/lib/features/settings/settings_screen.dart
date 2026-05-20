import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agents/tools/ticket_tool.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../providers.dart';
import '../../widgets/atoms/empty_state.dart';
import '../../widgets/atoms/mono_text.dart';
import '../architecture/architecture_screen.dart';
import '../onboarding/location_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _logoTaps = 0;
  DateTime? _firstTapAt;

  void _onLogoTap() {
    final now = DateTime.now();
    if (_firstTapAt == null ||
        now.difference(_firstTapAt!).inMilliseconds > 3000) {
      _firstTapAt = now;
      _logoTaps = 1;
      return;
    }
    _logoTaps++;
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      _firstTapAt = null;
      Haptics.medium();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ArchitectureScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = ref.watch(demoModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final autoPlay = ref.watch(autoPlayProvider);
    final speed = ref.watch(playbackSpeedProvider);
    final locale = ref.watch(appLocaleProvider);
    final userLocation = ref.watch(userLocationProvider);

    final geminiKey = (dotenv.maybeGet('GEMINI_API_KEY') ?? '').trim();
    final anthropicKey = (dotenv.maybeGet('LLM_API_KEY') ?? '').trim();
    final apiConnected = geminiKey.isNotEmpty || anthropicKey.isNotEmpty;
    final apiProviderLabel = geminiKey.isNotEmpty
        ? 'Gemini connected'
        : anthropicKey.isNotEmpty
            ? 'Claude connected'
            : 'Not configured';

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceElevated,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: _onLogoTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'SETTINGS',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ),
      ),
      body: ListView(
        children: [
          _SectionLabel(label: 'LOCATION'),
          ListTile(
            leading: const Icon(Icons.location_on_outlined,
                color: AppColors.signalBlue),
            title: Text(
              userLocation?.city ?? 'Not set',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Primary city — drives weather, map & alerts',
              style: AppTypography.bodyMedium,
            ),
            trailing: TextButton(
              onPressed: () => _showLocationPicker(context),
              child: Text(
                'CHANGE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.signalBlue,
                ),
              ),
            ),
          ),

          _SectionLabel(label: 'APPEARANCE'),
          SwitchListTile(
            value: themeMode == ThemeMode.dark,
            onChanged: (v) {
              Haptics.light();
              ref.read(themeModeProvider.notifier).state =
                  v ? ThemeMode.dark : ThemeMode.light;
            },
            activeColor: AppColors.signalBlue,
            title: const Text('Dark Mode'),
            subtitle: Text(
              themeMode == ThemeMode.dark ? 'Dark theme active' : 'Light theme active',
              style: AppTypography.bodyMedium,
            ),
            secondary: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),

          _SectionLabel(label: 'DEMO'),
          SwitchListTile(
            value: demoMode,
            onChanged: (v) {
              Haptics.light();
              ref.read(demoModeProvider.notifier).state = v;
            },
            activeColor: AppColors.signalBlue,
            title: const Text('Demo Mode'),
            subtitle: Text(
              demoMode
                  ? 'All LLM calls use mock responses'
                  : 'Live LLM calls (if API key set)',
              style: AppTypography.bodyMedium,
            ),
            secondary: const Icon(Icons.science_outlined),
          ),
          SwitchListTile(
            value: autoPlay,
            onChanged: (v) {
              Haptics.light();
              ref.read(autoPlayProvider.notifier).state = v;
            },
            activeColor: AppColors.signalBlue,
            title: const Text('Auto-play demo sequence'),
            subtitle: Text(
              'Queue 3 demo signals automatically on Home',
              style: AppTypography.bodyMedium,
            ),
            secondary: const Icon(Icons.play_circle_outline),
          ),
          _PlaybackSpeedRow(
            speed: speed,
            onChanged: (v) {
              Haptics.light();
              ref.read(playbackSpeedProvider.notifier).state = v;
            },
          ),

          _SectionLabel(label: 'LANGUAGE'),
          _LanguageRow(
            locale: locale,
            onChanged: (v) {
              Haptics.light();
              ref.read(appLocaleProvider.notifier).state = v;
            },
          ),

          _SectionLabel(label: 'API'),
          ListTile(
            leading: Icon(
              Icons.cloud_outlined,
              color: apiConnected ? AppColors.low : AppColors.critical,
            ),
            title: const Text('API Key Status'),
            subtitle: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: apiConnected ? AppColors.low : AppColors.critical,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  apiProviderLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color:
                        apiConnected ? AppColors.low : AppColors.critical,
                  ),
                ),
              ],
            ),
          ),

          _SectionLabel(label: 'DATA'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Demo Data'),
            subtitle: Text('Reload all mock crises, signals, and tickets',
                style: AppTypography.bodyMedium),
            onTap: () async {
              await Haptics.medium();
              ref.read(crisisListProvider.notifier).reset();
              ref.read(signalListProvider.notifier).reset();
              TicketTool.clearLog();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceCard,
                    content: MonoText('Demo data reset',
                        fontSize: 12, color: AppColors.low),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('View Execution Log'),
            subtitle: Text(
                '${TicketTool.executionLog.length} tickets created this session',
                style: AppTypography.bodyMedium),
            onTap: () => _showExecutionLog(context),
          ),
          const SizedBox(height: 32),
          Center(
            child: MonoText('v1.0.0 — PAK·PULSE',
                fontSize: 10, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(sheetCtx).size.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change City',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LocationPicker(
                    onPicked: (loc) async {
                      await ref
                          .read(userLocationProvider.notifier)
                          .setLocation(loc);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceCard,
                            content: MonoText(
                              'Location updated · ${loc.city}',
                              fontSize: 12,
                              color: AppColors.low,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExecutionLog(BuildContext context) {
    final log = TicketTool.executionLog;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('EXECUTION LOG',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  MonoText('${log.length} entries',
                      fontSize: 10, color: AppColors.textTertiary),
                ],
              ),
            ),
            Divider(color: AppColors.borderSubtle, height: 1),
            Expanded(
              child: log.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.inbox_outlined,
                      title: 'No tickets created yet',
                      subtitle:
                          'Execute actions in the Action Console to populate this log.',
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: log.length,
                      itemBuilder: (_, i) {
                        final t = log[log.length - 1 - i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundBase,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  MonoText(t.ticketId,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.low),
                                  const Spacer(),
                                  MonoText(t.agency,
                                      fontSize: 10,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.crisisType.toUpperCase()} · ${t.sector}',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: 2),
                              MonoText(
                                t.createdAt.toIso8601String(),
                                fontSize: 9,
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(label, style: AppTypography.labelSmall),
    );
  }
}

class _PlaybackSpeedRow extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;
  const _PlaybackSpeedRow({required this.speed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.speed),
      title: const Text('Playback speed'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SegmentedButton<double>(
          segments: const [
            ButtonSegment(value: 1.0, label: Text('1x')),
            ButtonSegment(value: 2.0, label: Text('2x')),
            ButtonSegment(value: 5.0, label: Text('5x')),
          ],
          selected: {speed},
          showSelectedIcon: false,
          onSelectionChanged: (v) => onChanged(v.first),
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(
                GoogleFonts.jetBrainsMono(fontSize: 11)),
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String locale;
  final ValueChanged<String> onChanged;
  const _LanguageRow({required this.locale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('App Language'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SegmentedButton<String>(
          segments: [
            const ButtonSegment(value: 'en', label: Text('EN')),
            ButtonSegment(
                value: 'ur',
                label: Text('اردو',
                    style: TextStyle(fontFamily: 'NotoNastaliqUrdu'))),
            const ButtonSegment(value: 'roman', label: Text('Roman')),
          ],
          selected: {locale},
          showSelectedIcon: false,
          onSelectionChanged: (v) => onChanged(v.first),
        ),
      ),
    );
  }
}
