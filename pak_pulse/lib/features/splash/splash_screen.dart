import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../data/services/location_service.dart';
import '../../widgets/atoms/rotating_globe.dart';

/// Boot screen — a revolving 3D globe over a staggered initialisation
/// sequence, themed to the PAK·PULSE ops-console brand.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const List<String> _phases = [
    'Connecting to PakMet feed',
    'Linking social signal grid',
    'Booting 4-agent pipeline',
    'Restoring operations cache',
    'Establishing secure tunnel',
    'Calibrating Islamabad geo-fence',
    'Systems ready',
  ];

  static const List<_Agent> _agents = [
    _Agent('SIGNAL', AppColors.agentSignal),
    _Agent('DETECT', AppColors.agentDetection),
    _Agent('SEVERITY', AppColors.agentSeverity),
    _Agent('ACTION', AppColors.agentAction),
  ];

  int _step = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 430), (timer) {
      if (!mounted) return;
      if (_step >= _phases.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _step++);
    });
    Future.delayed(const Duration(milliseconds: 3300), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    // A primary city must be captured before Home loads — if onboarding
    // finished but no location was stored, route back through onboarding.
    final locationSet = await LocationService.isLocationSet();
    if (!mounted) return;
    context.go(onboardingDone && locationSet ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                _bootStamp(),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(width: 320, child: _centerpiece()),
                    ),
                  ),
                ),
                _statusBlock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ambient backdrop ───────────────────────────────────────────────────────

  Widget _backdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -110,
            child: _orb(320, AppColors.critical.withOpacity(0.16)),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _orb(360, AppColors.signalBlue.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }

  // ── Top boot stamp ─────────────────────────────────────────────────────────

  Widget _bootStamp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.low,
              boxShadow: [
                BoxShadow(color: AppColors.low, blurRadius: 7, spreadRadius: 1),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 1.0, end: 0.25, duration: 900.ms, curve: AppMotion.soft),
          const SizedBox(width: 8),
          Text('SYSTEM · BOOT v1.0.0', style: _mono(9.5, AppColors.textTertiary)),
          const Spacer(),
          Text('OPS-CORE', style: _mono(9.5, AppColors.textTertiary)),
        ],
      ),
    ).animate(delay: 60.ms).fadeIn(duration: 600.ms, curve: AppMotion.spring);
  }

  // ── Centerpiece — globe + wordmark ─────────────────────────────────────────

  Widget _centerpiece() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RotatingGlobe(size: 224)
            .animate(delay: 140.ms)
            .fadeIn(duration: 900.ms, curve: AppMotion.spring)
            .slideY(begin: 0.16, end: 0, duration: 900.ms, curve: AppMotion.spring),
        const SizedBox(height: 26),
        _rise(
          delay: 260,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAK·PULSE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.critical,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.critical.withOpacity(0.6),
                        blurRadius: 9,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 1.0, end: 0.35, duration: 850.ms, curve: AppMotion.soft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _rise(
          delay: 340,
          child: Text(
            'CRISIS · INTELLIGENCE · RESPONSE',
            style: _mono(10, AppColors.textTertiary),
          ),
        ),
        const SizedBox(height: 22),
        _rise(
          delay: 440,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(0.6),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              "For Pakistan's cities, in real time",
              style: GoogleFonts.instrumentSerif(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _rise(
          delay: 520,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'پاکستان کے شہروں کے لیے — حقیقی وقت میں',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom status block ────────────────────────────────────────────────────

  Widget _statusBlock() {
    final pct = ((_step / (_phases.length - 1)) * 100).round();
    final now = DateTime.now();
    final date = '${now.year}.${_two(now.month)}.${_two(now.day)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
      child: Column(
        children: [
          _rise(
            delay: 620,
            child: _bezel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('INITIALIZING', style: _mono(9.5, AppColors.textTertiary)),
                      const Spacer(),
                      Text('${_two(pct)}%', style: _mono(10, AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _progressBar(),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.signalBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_phases[_step]}…',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _agents.length; i++)
                        _agentDot(_agents[i], _step > i + 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _rise(
            delay: 720,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NODE · ISB-METRO-01', style: _mono(9, AppColors.textTertiary)),
                Text('SECURE TLS', style: _mono(9, AppColors.textTertiary)),
                Text(date, style: _mono(9, AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        children: [
          Container(height: 3, color: AppColors.borderSubtle.withOpacity(0.5)),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 430),
            curve: AppMotion.spring,
            widthFactor: (_step / (_phases.length - 1)).clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.signalBlue,
                    AppColors.high,
                    AppColors.low,
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1400.ms, color: Colors.white.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }

  Widget _agentDot(_Agent agent, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: AppMotion.spring,
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? agent.color : Colors.transparent,
            border: Border.all(
              color: active ? agent.color : AppColors.borderSubtle,
              width: 1.2,
            ),
            boxShadow: active
                ? [BoxShadow(color: agent.color.withOpacity(0.6), blurRadius: 9)]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          agent.label,
          style: _mono(8.5, active ? AppColors.textSecondary : AppColors.textTertiary),
        ),
      ],
    );
  }

  // ── Shared chrome ──────────────────────────────────────────────────────────

  /// Double-bezel card: hairline outer shell wrapping an elevated inner core.
  Widget _bezel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.textPrimary.withOpacity(0.07),
            AppColors.textPrimary.withOpacity(0.02),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: child,
      ),
    );
  }

  /// Staggered fade-and-rise entrance — the design system's `ciro-rise`.
  Widget _rise({required int delay, required Widget child}) {
    return child
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 700.ms, curve: AppMotion.spring)
        .slideY(begin: 0.34, end: 0, duration: 700.ms, curve: AppMotion.spring);
  }

  TextStyle _mono(double size, Color color) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w500,
      );

  String _two(int n) => n.toString().padLeft(2, '0');
}

class _Agent {
  const _Agent(this.label, this.color);
  final String label;
  final Color color;
}
