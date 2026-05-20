import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../data/models/user_location.dart';
import '../../providers.dart';
import '../../widgets/pp_chrome.dart';
import 'location_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  final List<AnimationController> _ringCtls = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + i * 600),
      )..repeat(reverse: false);
      _ringCtls.add(c);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _ringCtls) {
      c.dispose();
    }
    super.dispose();
  }

  /// Completes onboarding once a city has been chosen. The location is
  /// persisted (via the provider) and onboarding is marked done so neither
  /// the intro nor the location prompt is ever shown again.
  Future<void> _finish(UserLocation location) async {
    await ref.read(userLocationProvider.notifier).setLocation(location);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/home');
  }

  /// Skipping the intro jumps straight to the location step — a primary city
  /// must always be captured before the home screen loads.
  void _skip() {
    _pageCtrl.animateToPage(
      3,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // Skip link
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        0, 12, 20, 0),
                    child: GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                          decoration:
                              TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (p) =>
                        setState(() => _page = p),
                    children: [
                      _PageOne(ringCtls: _ringCtls),
                      const _PageTwo(),
                      const _PageThree(),
                      _PageFour(onPicked: _finish),
                    ],
                  ),
                ),
                _BottomControls(
                  page: _page,
                  onNext: () {
                    if (_page < 3) {
                      _pageCtrl.nextPage(
                        duration: const Duration(
                            milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page One: Crisis Intelligence ─────────────────────────────────────────────

class _PageOne extends StatelessWidget {
  final List<AnimationController> ringCtls;
  const _PageOne({required this.ringCtls});

  @override
  Widget build(BuildContext context) {
    // Heatwave gradient — Pakistan is in extreme-heat season May–June.
    // Inner ring: orange (moderate heat), outer rings escalate to critical red.
    final colors = [
      AppColors.moderate,      // 38°C zone — yellow-amber
      AppColors.heatOrange,    // 45°C zone — deep orange
      AppColors.critical,      // 50°C+ zone — red alert
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulse rings + globe icon
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: ringCtls[i],
                    builder: (_, __) {
                      final v = ringCtls[i].value;
                      return Opacity(
                        opacity:
                            (1 - v).clamp(0.0, 1.0),
                        child: Container(
                          width: 70 + v * 150,
                          height: 70 + v * 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors[i]
                                  .withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Globe icon in center
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(
                        color: AppColors.heatOrange
                            .withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.heatOrange
                            .withOpacity(0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: AppColors.heatOrange,
                    size: 32,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 40),
          PPEyebrow('PAGE 1 OF 3'),
          const SizedBox(height: 8),
          Text(
            'Crisis Intelligence',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
          Text(
            '4 AI agents working together to detect, analyse, and respond to crises in real time.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'پاکستان کا بحران انٹیلی جنس سسٹم',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 16,
                height: 1.8,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(delay: 500.ms)
              .fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}

// ── Page Two: 4-Agent Pipeline ────────────────────────────────────────────────

class _PageTwo extends StatelessWidget {
  const _PageTwo();

  @override
  Widget build(BuildContext context) {
    final agents = [
      (AgentColors.forAgent(AgentName.signal), 'S',
          'Signal', Icons.wifi_tethering),
      (AgentColors.forAgent(AgentName.detection), 'D',
          'Detection', Icons.radar),
      (AgentColors.forAgent(AgentName.severity), 'Sv',
          'Severity', Icons.analytics_outlined),
      (AgentColors.forAgent(AgentName.action), 'A',
          'Action', Icons.task_alt_outlined),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Agent flow with arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: agents
                .asMap()
                .entries
                .map((e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: e.value.$1
                                    .withOpacity(0.15),
                                border: Border.all(
                                    color: e.value.$1,
                                    width: 2),
                              ),
                              child: Center(
                                child: Icon(
                                  e.value.$4,
                                  color: e.value.$1,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.value.$3.toUpperCase(),
                              style: GoogleFonts
                                  .jetBrainsMono(
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w700,
                                color: e.value.$1,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ).animate(
                            delay: Duration(
                                milliseconds:
                                    e.key * 150)).fadeIn(
                            duration: 500.ms).slideY(
                            begin: 0.3, end: 0),
                        if (e.key < agents.length - 1)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                                    bottom: 20,
                                    left: 4,
                                    right: 4),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: AppColors
                                  .textTertiary,
                            ),
                          ).animate(
                              delay: Duration(
                                  milliseconds: e.key *
                                          150 +
                                      100)).fadeIn(
                              duration: 400.ms),
                      ],
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
          PPEyebrow('PAGE 2 OF 3'),
          const SizedBox(height: 8),
          Text(
            '4-Agent Pipeline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 600.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            'Signal → Detection → Severity → Action. Fully traceable AI reasoning.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 750.ms)
              .fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'چار ایجنٹ۔ ایک مقصد',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 16,
                height: 1.8,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(delay: 900.ms)
              .fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}

// ── Page Three: Real-Time Response ────────────────────────────────────────────

class _PageThree extends StatelessWidget {
  const _PageThree();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Checkmark with green glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.low.withOpacity(0.12),
              border: Border.all(
                  color: AppColors.low.withOpacity(0.4),
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.low.withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.low,
              size: 48,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.6, 0.6)),
          const SizedBox(height: 40),
          PPEyebrow('PAGE 3 OF 3'),
          const SizedBox(height: 8),
          Text(
            'Real-Time Response',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            'Instant action recommendations delivered when seconds count.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 600.ms),
          const SizedBox(height: 28),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'سگنل دو، باقی ہم سنبھال لیں گے',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                height: 1.8,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(delay: 500.ms)
              .fadeIn(duration: 700.ms),
          const SizedBox(height: 8),
          Text(
            'Signal do. Baqi hum sambhal lenge.',
            style: GoogleFonts.instrumentSerif(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 650.ms)
              .fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}

// ── Bottom Controls ───────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final int page;
  final VoidCallback onNext;

  const _BottomControls(
      {required this.page, required this.onNext});

  @override
  Widget build(BuildContext context) {
    // The location step (page 3) carries its own actions, so the shared
    // Continue button is hidden there.
    final isLocationPage = page == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          // Dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(
                    horizontal: 4),
                width: i == page ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == page
                      ? AppColors.critical
                      : AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          if (!isLocationPage) ...[
            const SizedBox(height: 24),
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.critical,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text(
                  'CONTINUE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Page Four: Location ───────────────────────────────────────────────────────

class _PageFour extends StatelessWidget {
  final void Function(UserLocation) onPicked;
  const _PageFour({required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.signalBlue.withOpacity(0.12),
              border: Border.all(
                  color: AppColors.signalBlue.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.location_on,
                color: AppColors.signalBlue, size: 34),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.7, 0.7)),
          const SizedBox(height: 20),
          PPEyebrow('PAGE 4 OF 4'),
          const SizedBox(height: 8),
          Text(
            'Your City',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Set your primary city so weather, maps and alerts match where you are.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LocationPicker(onPicked: onPicked),
          ),
        ],
      ),
    );
  }
}
