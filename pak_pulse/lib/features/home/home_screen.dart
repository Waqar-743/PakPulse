import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agents/orchestrator_providers.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis.dart';
import '../../data/models/live_conditions.dart';
import '../../providers.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/atoms/severity_chip.dart';
import '../../widgets/atoms/shimmer_skeleton.dart';
import '../../widgets/organisms/crisis_map.dart';
import '../../widgets/organisms/disaster_feed_card.dart';
import '../../widgets/organisms/notification_banner.dart';
import '../../widgets/organisms/signal_stream_widget.dart';
import '../../widgets/pp_chrome.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ── Auto-play ──────────────────────────────────────────────────────────────
  static const _demoSignals = [
    'G-10 mein pani bhar gaya, gaariyan phans gayi hain',
    'Jacobabad mein garmi 51 degree ho gayi, AC bhi kaam nahi kar raha',
    'Faizabad block ho gaya, dharna shuru ho gaya hai',
  ];

  final List<Timer> _autoPlayTimers = [];
  bool _autoPlayStarted = false;

  // ── Social pulse rotation ─────────────────────────────────────────────────
  int _pulseDotIndex = 0;
  int _pulseSignalIndex = 0;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(autoPlayProvider)) _startAutoPlay();
      _startPulseRotation();
    });
  }

  void _startPulseRotation() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted) {
        setState(() {
          _pulseDotIndex = (_pulseDotIndex + 1) % 3;
          _pulseSignalIndex = (_pulseSignalIndex + 1) %
              (ref.read(signalListProvider).length.clamp(1, 999));
        });
      }
    });
  }

  @override
  void dispose() {
    _cancelAutoPlay();
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _cancelAutoPlay() {
    for (final t in _autoPlayTimers) {
      t.cancel();
    }
    _autoPlayTimers.clear();
    _autoPlayStarted = false;
  }

  void _startAutoPlay() {
    if (_autoPlayStarted) return;
    _autoPlayStarted = true;
    final speed = ref.read(playbackSpeedProvider);
    final initialDelay = Duration(milliseconds: (3000 / speed).round());
    final spacing = Duration(milliseconds: (8000 / speed).round());

    for (var i = 0; i < _demoSignals.length; i++) {
      final delay = initialDelay + spacing * i;
      _autoPlayTimers.add(Timer(delay, () => _fireDemoSignal(i)));
    }
  }

  void _fireDemoSignal(int index) {
    if (!mounted) return;
    final text = _demoSignals[index];
    final isLast = index == _demoSignals.length - 1;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceCard,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.bolt, color: AppColors.signalBlue, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: MonoText(
                'DEMO SIGNAL ${index + 1}/3',
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    if (isLast) {
      context.push('/trace/new?signal=${Uri.encodeComponent(text)}');
    } else {
      ref.read(orchestratorControllerProvider.notifier).runPipeline(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // React to auto-play toggle being flipped at runtime.
    ref.listen<bool>(autoPlayProvider, (prev, next) {
      if (next && !(prev ?? false)) {
        _startAutoPlay();
      } else if (!next) {
        _cancelAutoPlay();
      }
    });

    // Activate the auto-verifier — listens to clustered citizen signals and
    // runs the 6-agent verification pipeline whenever a new cluster qualifies.
    ref.watch(autoVerifierProvider);

    final crises = ref.watch(crisisListProvider);
    final signals = ref.watch(signalListProvider);
    final activeCrises = crises.where((c) => c.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chat'),
        backgroundColor: AppColors.signalBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Ask',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          const PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // ── App Header ──────────────────────────────────────────────
                _AppHeader(signalCount: signals.length),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Verified-crisis notification banner ─────────────
                        const NotificationBanner(),
                        // ── Hero Alert Card ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: activeCrises.isEmpty
                              ? const _AllClearCard().animate(delay: 100.ms).fadeIn(
                                    duration: 700.ms,
                                    curve: Cubic(0.32, 0.72, 0, 1),
                                  )
                              : _HeroAlertCard(crisis: activeCrises.first)
                                  .animate(delay: 100.ms)
                                  .fadeIn(
                                    duration: 700.ms,
                                    curve: Cubic(0.32, 0.72, 0, 1),
                                  )
                                  .slideY(
                                    begin: 0.3,
                                    end: 0,
                                    duration: 700.ms,
                                    curve: Cubic(0.32, 0.72, 0, 1),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        // ── 3-Stat Row ──────────────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: _StatRow(
                            activeCrises: activeCrises.length,
                            signalCount: signals.length,
                          ),
                        )
                            .animate(delay: 200.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            )
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // ── Live Weather (user's stored city) ────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: const _LocationWeatherCard(),
                        )
                            .animate(delay: 250.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            )
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // ── Agent Pipeline Strip ─────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: PPSectionHeader(
                            kicker: 'REAL-TIME · AI PIPELINE',
                            title: 'Agent Status',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AgentPipelineStrip()
                            .animate(delay: 300.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // ── Map ──────────────────────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: PPSectionHeader(
                            kicker: 'SPATIAL · OVERVIEW',
                            title: 'Crisis Map',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: PPBezel(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: SizedBox(
                                height: 240,
                                child: crises.isEmpty
                                    ? const ShimmerSkeleton(
                                        width: double.infinity,
                                        height: 240,
                                        radius: 21,
                                      )
                                    : CrisisMap(
                                        crises: crises,
                                        onMarkerTap: (c) =>
                                            context.push('/crisis/${c.id}'),
                                      ),
                              ),
                            ),
                          ),
                        )
                            .animate(delay: 400.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // ── Signal Stream ───────────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: PPSectionHeader(
                            kicker: 'LIVE · FEED',
                            title: 'Signal Stream',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 260,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: AppColors.borderSubtle),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: const SignalStreamWidget(),
                          ),
                        )
                            .animate(delay: 500.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // ── Social Pulse ─────────────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: _SocialPulseCard(
                            signals: signals,
                            activeIndex: _pulseSignalIndex,
                            dotIndex: _pulseDotIndex,
                          ),
                        )
                            .animate(delay: 600.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 16),
                        // ── Regional Disaster Feed (GDACS — live) ────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: PPSectionHeader(
                            kicker: 'GLOBAL · DISASTER WATCH',
                            title: 'Regional Flood Watch',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: const DisasterFeedCard(),
                        )
                            .animate(delay: 650.ms)
                            .fadeIn(
                              duration: 700.ms,
                              curve: Cubic(0.32, 0.72, 0, 1),
                            ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── FAB ────────────────────────────────────────────────────────────
          Positioned(
            bottom: 20,
            right: 16,
            child: GestureDetector(
              onTap: () => _showNewSignalSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.critical,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.critical.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'ADD SIGNAL',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewSignalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _NewSignalSheet(
        onPipelineRun: (text) {
          context.push('/trace/new?signal=${Uri.encodeComponent(text)}');
        },
      ),
    );
  }
}

// ── App Header ────────────────────────────────────────────────────────────────

class _AppHeader extends StatefulWidget {
  final int signalCount;
  const _AppHeader({required this.signalCount});

  @override
  State<_AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<_AppHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PPEyebrow('LIVE · PKT · OPERATIONS'),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.critical
                              .withOpacity(_pulseAnim.value),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.critical.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'PakPulse',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.critical.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.critical.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                MonoText(
                  '${widget.signalCount}',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.critical,
                ),
                MonoText(
                  'SIGNALS',
                  fontSize: 8,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Alert Card ───────────────────────────────────────────────────────────

class _HeroAlertCard extends StatelessWidget {
  final Crisis crisis;
  const _HeroAlertCard({required this.crisis});

  @override
  Widget build(BuildContext context) {
    final crisisColor = AgentColors.forCrisis(crisis.type);
    final timeAgo = _timeAgo(crisis.detectedAt);

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.critical.withOpacity(0.15),
            AppColors.critical.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.critical.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scan line
            const PPScanLine(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow + type badge
                  Row(
                    children: [
                      PPEyebrow(
                        '● CRITICAL ALERT · ${crisis.type.label.toUpperCase()}',
                        color: AppColors.critical,
                      ),
                      const Spacer(),
                      SeverityChip(severity: crisis.severity),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    crisis.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Urdu subtitle
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      crisis.summaryUr,
                      style: GoogleFonts.notoNastaliqUrdu(
                        fontSize: 13,
                        height: 1.9,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location + time row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      MonoText(
                        crisis.sector,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_outlined,
                          size: 12,
                          color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      MonoText(
                        timeAgo,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      const Spacer(),
                      // Confidence gauge
                      _ConfidenceBadge(
                          confidence: crisis.confidence,
                          color: crisisColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // CTA row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/crisis/${crisis.id}'),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.critical,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'OPEN',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppColors.borderSubtle),
                            ),
                            child: Center(
                              child: Text(
                                'MUTE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── All Clear Card ────────────────────────────────────────────────────────────

class _AllClearCard extends ConsumerWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.low.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.low.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.low.withOpacity(0.12),
                  border: Border.all(color: AppColors.low.withOpacity(0.4)),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.low, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PPEyebrow('● ALL CLEAR · NO ACTIVE CRISES',
                        color: AppColors.low),
                    const SizedBox(height: 4),
                    Text(
                      'Situation Normal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'No active crises detected by the AI pipeline. '
            'Use the Signal Inbox to submit a new report, or tap ADD SIGNAL below.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'کوئی فعال بحران نہیں — صورتحال معمول کے مطابق ہے',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 13,
                height: 1.9,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  final Color color;
  const _ConfidenceBadge({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: confidence,
            strokeWidth: 3,
            backgroundColor: AppColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          MonoText(
            '${(confidence * 100).round()}',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final int activeCrises;
  final int signalCount;

  const _StatRow({
    required this.activeCrises,
    required this.signalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          kicker: 'ACTIVE',
          label: 'INCIDENTS',
          value: '$activeCrises',
          accent: AppColors.critical,
        ),
        const SizedBox(width: 8),
        _StatTile(
          kicker: 'AI AGENTS',
          label: 'ONLINE',
          value: '4/4',
          accent: AppColors.low,
        ),
        const SizedBox(width: 8),
        _StatTile(
          kicker: 'SIGNALS',
          label: 'CAPTURED',
          value: '$signalCount',
          accent: AppColors.signalBlue,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String kicker;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.kicker,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PPEyebrow(kicker),
            const SizedBox(height: 4),
            MonoText(
              value,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
            const SizedBox(height: 2),
            MonoText(
              label,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Agent Pipeline Strip ──────────────────────────────────────────────────────

class _AgentPipelineStrip extends ConsumerWidget {
  static const _agents = [
    AgentName.signal,
    AgentName.detection,
    AgentName.severity,
    AgentName.action,
  ];
  static const _roles = [
    'Signal\nAnalyst',
    'Crisis\nDetector',
    'Severity\nRanker',
    'Action\nPlanner',
  ];
  static const _agentIcons = [
    Icons.wifi_tethering,
    Icons.radar,
    Icons.analytics_outlined,
    Icons.task_alt_outlined,
  ];

  const _AgentPipelineStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orchestratorControllerProvider);
    final isRunning = state.isRunning;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _agents.length,
        itemBuilder: (_, i) {
          final agent = _agents[i];
          final color = AgentColors.forAgent(agent);
          final hasStep =
              state.trace.any((s) => s.agentName == agent);
          final isCurrentlyRunning = isRunning &&
              state.events.isNotEmpty &&
              state.events.last.agent == agent;

          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrentlyRunning
                    ? color.withOpacity(0.6)
                    : AppColors.borderSubtle,
                width: isCurrentlyRunning ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top color bar
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _agentIcons[i],
                              size: 14,
                              color: color,
                            ),
                          ),
                          const Spacer(),
                          if (hasStep)
                            Icon(Icons.check_circle,
                                size: 12, color: AppColors.low)
                          else if (isCurrentlyRunning)
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MonoText(
                        agent.name.toUpperCase(),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      Text(
                        _roles[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: hasStep
                              ? 1.0
                              : isCurrentlyRunning
                                  ? 0.5
                                  : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(1),
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
        },
      ),
    );
  }
}

// ── Social Pulse Card ─────────────────────────────────────────────────────────

class _SocialPulseCard extends StatelessWidget {
  final List signals;
  final int activeIndex;
  final int dotIndex;

  const _SocialPulseCard({
    required this.signals,
    required this.activeIndex,
    required this.dotIndex,
  });

  @override
  Widget build(BuildContext context) {
    final hasSignal = signals.isNotEmpty;
    final signal = hasSignal ? signals[activeIndex % signals.length] : null;

    return Container(
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
              PPEyebrow('SOCIAL · PULSE · LIVE'),
              const Spacer(),
              Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: i == dotIndex % 3 ? 14 : 5,
                    height: 5,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: i == dotIndex % 3
                          ? AppColors.signalBlue
                          : AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasSignal && signal != null)
            Text(
              signal.rawText,
              style: GoogleFonts.instrumentSerif(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          else
            MonoText(
              'Waiting for live signals…',
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}

// ── Location Weather Card ─────────────────────────────────────────────────────
// Live weather wired to the city the user chose during onboarding. All
// readings reflect their stored location, never a hardcoded one.

class _LocationWeatherCard extends ConsumerWidget {
  const _LocationWeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(userLocationProvider);
    final asyncWeather = ref.watch(userLiveConditionsProvider);
    final city = loc?.city ?? 'Islamabad';

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.location_on,
                  size: 18, color: AppColors.signalBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  city,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PPEyebrow('LIVE · WEATHER'),
            ],
          ),
          const SizedBox(height: 14),
          asyncWeather.when(
            loading: () => Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.signalBlue),
                ),
                const SizedBox(width: 12),
                Text(
                  'Fetching live weather…',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            error: (_, __) => _weatherUnavailable(),
            data: (c) =>
                c == null ? _weatherUnavailable() : _WeatherReadings(c),
          ),
        ],
      ),
    );
  }

  Widget _weatherUnavailable() => Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text(
            'Weather unavailable',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

class _WeatherReadings extends StatelessWidget {
  final LiveConditions c;
  const _WeatherReadings(this.c);

  Color get _tempColor {
    final t = c.temperatureC;
    if (t >= 45) return AppColors.critical;
    if (t >= 38) return AppColors.high;
    if (t >= 30) return AppColors.moderate;
    return AppColors.signalBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${c.temperatureC.round()}°',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: _tempColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.weatherLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.water_drop_outlined,
                      size: 14, color: AppColors.signalBlue),
                  const SizedBox(width: 4),
                  MonoText(
                    '${c.precipitationMmLastHour.toStringAsFixed(1)} mm',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.opacity,
                      size: 14, color: AppColors.signalBlue),
                  const SizedBox(width: 4),
                  MonoText(
                    '${c.humidityPercent.round()}%',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── New Signal Sheet ──────────────────────────────────────────────────────────

class _NewSignalSheet extends StatefulWidget {
  final void Function(String text) onPipelineRun;
  const _NewSignalSheet({required this.onPipelineRun});

  @override
  State<_NewSignalSheet> createState() => _NewSignalSheetState();
}

class _NewSignalSheetState extends State<_NewSignalSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PPEyebrow('NEW ENTRY · SIGNAL PIPELINE'),
            const SizedBox(height: 6),
            Text(
              'Add Signal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter signal in English, Roman Urdu, or Urdu script',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. G-10 mein pani bhar gaya...',
                hintStyle: AppTypography.bodyMedium,
                filled: true,
                fillColor: AppColors.backgroundBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.critical),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(context);
                  widget.onPipelineRun(text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.critical,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'RUN PIPELINE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
