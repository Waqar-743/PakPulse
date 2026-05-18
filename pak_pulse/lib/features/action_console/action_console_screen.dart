import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/crisis.dart';
import '../../data/models/crisis_action.dart';
import '../../providers.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/atoms/severity_chip.dart';
import '../../widgets/molecules/action_card.dart';
import '../../widgets/pp_chrome.dart';

class ActionConsoleScreen extends ConsumerStatefulWidget {
  const ActionConsoleScreen({super.key});

  @override
  ConsumerState<ActionConsoleScreen> createState() =>
      _ActionConsoleScreenState();
}

class _ActionConsoleScreenState
    extends ConsumerState<ActionConsoleScreen> {
  @override
  Widget build(BuildContext context) {
    final crises = ref
        .watch(crisisListProvider)
        .where((c) => c.isActive)
        .toList();

    final totalActions = crises.fold<int>(
        0, (a, c) => a + c.actions.length);
    final pending = crises.fold<int>(
      0,
      (a, c) => a +
          c.actions
              .where(
                  (x) => x.status == ActionStatus.pending)
              .length,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                _ConsoleHeader(
                  pending: pending,
                  total: totalActions,
                ),
                // ── Summary tiles ────────────────────────────
                if (crises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 12, 16, 0),
                    child: Row(
                      children: [
                        _SummaryTile(
                          kicker: 'ACTIVE CRISES',
                          value: '${crises.length}',
                          accent: AppColors.critical,
                        ),
                        const SizedBox(width: 8),
                        _SummaryTile(
                          kicker: 'TOTAL ACTIONS',
                          value: '$totalActions',
                          accent: AppColors.signalBlue,
                        ),
                        const SizedBox(width: 8),
                        _SummaryTile(
                          kicker: 'PENDING',
                          value: '$pending',
                          accent: AppColors.high,
                        ),
                      ],
                    ),
                  ).animate(delay: 50.ms).fadeIn(
                      duration: 500.ms,
                      curve: Cubic(0.32, 0.72, 0, 1)),
                const SizedBox(height: 12),
                // ── List ────────────────────────────────────
                Expanded(
                  child: crises.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 16),
                          itemCount: crises.length,
                          itemBuilder: (_, i) =>
                              _CrisisActionGroup(
                            crisis: crises[i],
                            index: i,
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

// ── Console Header ────────────────────────────────────────────────────────────

class _ConsoleHeader extends StatelessWidget {
  final int pending;
  final int total;

  const _ConsoleHeader({
    required this.pending,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
            bottom:
                BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PPEyebrow('RESPONSE · OPERATIONS'),
                const SizedBox(height: 2),
                Text(
                  'Action Console',
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
              color: AppColors.high.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.high.withOpacity(0.3)),
            ),
            child: MonoText(
              '$pending / $total PENDING',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.high,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Tile ──────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String kicker;
  final String value;
  final Color accent;

  const _SummaryTile({
    required this.kicker,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PPEyebrow(kicker),
            const SizedBox(height: 4),
            MonoText(
              value,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Crisis Action Group ───────────────────────────────────────────────────────

class _CrisisActionGroup extends StatefulWidget {
  final Crisis crisis;
  final int index;
  const _CrisisActionGroup(
      {required this.crisis, required this.index});

  @override
  State<_CrisisActionGroup> createState() =>
      _CrisisActionGroupState();
}

class _CrisisActionGroupState
    extends State<_CrisisActionGroup> {
  late List<CrisisAction> _actions;

  @override
  void initState() {
    super.initState();
    _actions =
        List<CrisisAction>.from(widget.crisis.actions);
  }

  @override
  void didUpdateWidget(_CrisisActionGroup old) {
    super.didUpdateWidget(old);
    if (old.crisis.id != widget.crisis.id) {
      _actions =
          List<CrisisAction>.from(widget.crisis.actions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.crisis;
    final crisisColor = AgentColors.forCrisis(c.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Crisis header card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: crisisColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SeverityChip(
                                      severity:
                                          c.severity),
                                  const SizedBox(
                                      width: 8),
                                  MonoText(
                                    'RSI ${c.riskScore}',
                                    fontSize: 10,
                                    color: AppColors
                                        .textSecondary,
                                  ),
                                  const SizedBox(
                                      width: 8),
                                  MonoText(
                                    c.sector,
                                    fontSize: 10,
                                    color: AppColors
                                        .textTertiary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        MonoText(
                          '${_actions.length} ACTIONS',
                          fontSize: 10,
                          color: crisisColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(
                delay: Duration(
                    milliseconds: 60 * widget.index))
            .fadeIn(
              duration: 500.ms,
              curve: Cubic(0.32, 0.72, 0, 1),
            ),
        // Action cards
        ..._actions.asMap().entries.map((entry) {
          final i = entry.key;
          final action = entry.value;
          if (action.type == ActionType.reroute) {
            return _RerouteActionCard(
              action: action,
              onExecuted: (updated) =>
                  setState(() => _actions[i] = updated),
            );
          }
          return ActionCard(
            action: action,
            onExecuted: (updated) =>
                setState(() => _actions[i] = updated),
          );
        }),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: AppColors.low),
          const SizedBox(height: 16),
          Text(
            'No active crises',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All clear — no pending action items',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Reroute Action Card ───────────────────────────────────────────────────────

class _RerouteActionCard extends StatefulWidget {
  final CrisisAction action;
  final ValueChanged<CrisisAction>? onExecuted;
  const _RerouteActionCard(
      {required this.action, this.onExecuted});

  @override
  State<_RerouteActionCard> createState() =>
      _RerouteActionCardState();
}

class _RerouteActionCardState
    extends State<_RerouteActionCard>
    with SingleTickerProviderStateMixin {
  CrisisAction? _executed;
  late final AnimationController _morphCtrl;

  @override
  void initState() {
    super.initState();
    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.action.status == ActionStatus.completed) {
      _executed = widget.action;
      _morphCtrl.value = 1;
    }
  }

  @override
  void dispose() {
    _morphCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionCard(
          action: widget.action,
          onExecuted: (updated) {
            setState(() => _executed = updated);
            _morphCtrl.forward(from: 0);
            widget.onExecuted?.call(updated);
          },
        ),
        if (_executed != null)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.borderSubtle),
              ),
              child: AnimatedBuilder(
                animation: _morphCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _RoutePainter(
                      progress: _morphCtrl.value),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: MonoText(
                          'REROUTE PREVIEW',
                          fontSize: 9,
                          color:
                              AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double progress;
  const _RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final oldRoute = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.4,
          size.width * 0.9,
          size.height * 0.5);

    final newRoute = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.85,
          size.width * 0.9,
          size.height * 0.5);

    final oldPaint = Paint()
      ..color = AppColors.critical
          .withOpacity((1 - progress).clamp(0.2, 1.0))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(oldRoute, oldPaint);

    if (progress > 0) {
      final metrics =
          newRoute.computeMetrics().toList();
      for (final m in metrics) {
        final extracted =
            m.extractPath(0, m.length * progress);
        final newPaint = Paint()
          ..color = AppColors.low
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(extracted, newPaint);
      }
    }

    final dot = Paint()..color = AppColors.textPrimary;
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.5),
        4,
        dot);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.5),
        4,
        dot);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.progress != progress;
}
