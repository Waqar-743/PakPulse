import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis_signal.dart';
import '../../providers.dart';
import '../atoms/shimmer_skeleton.dart';
import '../molecules/signal_card.dart';

class SignalStreamWidget extends ConsumerStatefulWidget {
  const SignalStreamWidget({super.key});

  @override
  ConsumerState<SignalStreamWidget> createState() => _SignalStreamWidgetState();
}

class _SignalStreamWidgetState extends ConsumerState<SignalStreamWidget> {
  final List<CrisisSignal> _liveSignals = [];
  static const int _maxVisible = 20;

  @override
  Widget build(BuildContext context) {
    ref.listen(signalSimulatorProvider, (_, next) {
      next.whenData((signal) {
        if (mounted) {
          setState(() {
            _liveSignals.insert(0, signal);
            if (_liveSignals.length > _maxVisible) {
              _liveSignals.removeLast();
            }
          });
        }
      });
    });

    final allSignals = ref.watch(signalListProvider);
    final displaySignals =
        _liveSignals.isEmpty ? allSignals.take(5).toList() : _liveSignals;

    return Column(
      children: [
        // Header
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: Row(
            children: [
              _LiveDot(),
              const SizedBox(width: 8),
              Text('LIVE SIGNALS', style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                letterSpacing: 1,
              )),
              const Spacer(),
              Text(
                '${allSignals.length} TOTAL',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: displaySignals.isEmpty
              ? const _StreamSkeleton()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  itemCount: displaySignals.length,
                  itemBuilder: (_, i) {
                    final signal = displaySignals[i];
                    final isNew = i == 0 && _liveSignals.isNotEmpty;
                    Widget card = SignalCard(
                      signal: signal,
                      compact: true,
                      onTap: () => showSignalDetail(context, signal),
                    );
                    if (isNew) {
                      card = card
                          .animate()
                          .slideX(begin: 1.0, duration: 400.ms, curve: Curves.easeOut)
                          .fadeIn(duration: 300.ms);
                    }
                    return card;
                  },
                ),
        ),
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.low.withOpacity(_anim.value),
        ),
      ),
    );
  }
}

class _StreamSkeleton extends StatelessWidget {
  const _StreamSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const ShimmerSkeleton(width: 36, height: 36, radius: 6),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerSkeleton(
                      width: double.infinity, height: 12, radius: 4),
                  const SizedBox(height: 4),
                  const ShimmerSkeleton(width: 80, height: 10, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
