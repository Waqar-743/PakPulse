import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agents/orchestrator.dart';
import '../../agents/orchestrator_providers.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/agent_step.dart';
import '../../providers.dart';
import '../../widgets/atoms/agent_thinking_dots.dart';
import '../../widgets/atoms/mono_text.dart';
import '../../widgets/organisms/agent_timeline.dart';
import '../../widgets/pp_chrome.dart';

class AgentTraceScreen extends ConsumerStatefulWidget {
  final String traceId;
  final String? liveSignalText;

  const AgentTraceScreen({
    super.key,
    required this.traceId,
    this.liveSignalText,
  });

  @override
  ConsumerState<AgentTraceScreen> createState() =>
      _AgentTraceScreenState();
}

class _AgentTraceScreenState
    extends ConsumerState<AgentTraceScreen> {
  Timer? _elapsedTicker;
  DateTime? _runStartedAt;

  bool get _isLive => widget.traceId == 'new';

  @override
  void initState() {
    super.initState();
    if (_isLive && (widget.liveSignalText ?? '').isNotEmpty) {
      _runStartedAt = DateTime.now();
      _elapsedTicker =
          Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(orchestratorControllerProvider.notifier)
            .runPipeline(widget.liveSignalText!);
      });
    }
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLive) return _buildLive();
    return _buildHistorical();
  }

  Widget _buildHistorical() {
    final crisis = ref.watch(crisisByIdProvider(widget.traceId));
    final steps = crisis?.reasoning ?? const <AgentStep>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                // Top nav
                _TraceNavRow(
                  runId: widget.traceId,
                  timing: steps.isNotEmpty
                      ? 'PIPELINE: ${_totalMs(steps)}ms'
                      : null,
                ),
                // Header
                _TraceHeader(
                  signalText: crisis?.title,
                  isLive: false,
                ),
                // Body
                Expanded(
                  child: steps.isEmpty
                      ? const _EmptyPipelineState()
                      : AgentTimeline(steps: steps),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLive() {
    final state = ref.watch(orchestratorControllerProvider);
    final events = state.events;
    final trace = state.trace;
    final completed = state.completedCrisis;

    final elapsedMs = _runStartedAt == null
        ? 0
        : DateTime.now()
            .difference(_runStartedAt!)
            .inMilliseconds;

    final timingLabel = state.isRunning
        ? 'PIPELINE: ${(elapsedMs / 1000).toStringAsFixed(1)}s'
        : 'PIPELINE: ${(_totalMs(trace) / 1000).toStringAsFixed(2)}s';

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          PPOrbs(),
          SafeArea(
            child: Column(
              children: [
                _TraceNavRow(runId: 'new', timing: timingLabel),
                _TraceHeader(
                  signalText: widget.liveSignalText,
                  isLive: true,
                ),
                _OrchestratorRibbon(
                  cycleCount: events.length,
                  isRunning: state.isRunning,
                ),
                Expanded(
                  child: _LivePipelineBody(
                      events: events, trace: trace),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: completed == null
          ? null
          : _CompletionBar(crisisId: completed.id),
    );
  }

  int _totalMs(List<AgentStep> steps) =>
      steps.fold(0, (a, s) => a + s.durationMs);
}

// ── Nav Row ───────────────────────────────────────────────────────────────────

class _TraceNavRow extends StatelessWidget {
  final String runId;
  final String? timing;

  const _TraceNavRow({required this.runId, this.timing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          PPEyebrow('RUN · ${runId.toUpperCase()}'),
          const Spacer(),
          if (timing != null)
            MonoText(
              timing!,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          const SizedBox(width: 8),
          Icon(Icons.share_outlined,
              size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TraceHeader extends StatelessWidget {
  final String? signalText;
  final bool isLive;

  const _TraceHeader({this.signalText, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PPEyebrow('4-AGENT PIPELINE'),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Reasoning',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'transparency',
                style: GoogleFonts.instrumentSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (signalText != null) ...[
            const SizedBox(height: 6),
            Text(
              '"$signalText"',
              style: GoogleFonts.instrumentSerif(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Orchestrator Ribbon ───────────────────────────────────────────────────────

class _OrchestratorRibbon extends StatefulWidget {
  final int cycleCount;
  final bool isRunning;

  const _OrchestratorRibbon(
      {required this.cycleCount, required this.isRunning});

  @override
  State<_OrchestratorRibbon> createState() =>
      _OrchestratorRibbonState();
}

class _OrchestratorRibbonState extends State<_OrchestratorRibbon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _spinCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _spinCtrl.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.signalBlue.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.radar,
                size: 14,
                color: AppColors.signalBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PPEyebrow('ORCHESTRATOR'),
              MonoText(
                widget.isRunning
                    ? 'PIPELINE RUNNING'
                    : 'PIPELINE COMPLETE',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.isRunning
                    ? AppColors.signalBlue
                    : AppColors.low,
              ),
            ],
          ),
          const Spacer(),
          MonoText(
            '${widget.cycleCount} EVENTS',
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Live pipeline body ────────────────────────────────────────────────────────

class _LivePipelineBody extends StatelessWidget {
  final List<OrchestratorEvent> events;
  final List<AgentStep> trace;

  const _LivePipelineBody(
      {required this.events, required this.trace});

  static const _orderedAgents = [
    AgentName.signal,
    AgentName.detection,
    AgentName.severity,
    AgentName.action,
  ];

  AgentName? get _runningAgent {
    if (events.isEmpty) return _orderedAgents.first;
    final last = events.last;
    if (last.phase == OrchestratorPhase.agentStarted) {
      return last.agent;
    }
    if (last.phase == OrchestratorPhase.pipelineComplete) {
      return null;
    }
    if (last.phase == OrchestratorPhase.agentCompleted &&
        last.agent != null) {
      final idx = _orderedAgents.indexOf(last.agent!);
      if (idx >= 0 && idx + 1 < _orderedAgents.length) {
        return _orderedAgents[idx + 1];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const _EmptyPipelineState();

    final running = _runningAgent;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _orderedAgents.length,
      itemBuilder: (_, i) {
        final agent = _orderedAgents[i];
        AgentStep? step;
        for (final s in trace) {
          if (s.agentName == agent) {
            step = s;
            break;
          }
        }

        final isThinking = running == agent;

        return Column(
          children: [
            _CIROAgentCard(
              agent: agent,
              step: step,
              isThinking: isThinking,
              index: i,
            ),
            if (i < _orderedAgents.length - 1)
              _HandoffLine(
                from: agent,
                completed: step?.isCompleted ?? false,
              ),
          ],
        );
      },
    );
  }
}

// ── CIRO Agent Card ───────────────────────────────────────────────────────────

class _CIROAgentCard extends StatefulWidget {
  final AgentName agent;
  final AgentStep? step;
  final bool isThinking;
  final int index;

  const _CIROAgentCard({
    required this.agent,
    required this.step,
    required this.isThinking,
    required this.index,
  });

  @override
  State<_CIROAgentCard> createState() => _CIROAgentCardState();
}

class _CIROAgentCardState extends State<_CIROAgentCard> {
  bool _expanded = false;

  static const _urduNames = {
    AgentName.signal: 'سگنل ایجنٹ',
    AgentName.detection: 'ڈیٹیکشن ایجنٹ',
    AgentName.severity: 'شدت ایجنٹ',
    AgentName.action: 'ایکشن ایجنٹ',
  };

  static const _roles = {
    AgentName.signal: 'Signal Analyst',
    AgentName.detection: 'Crisis Detector',
    AgentName.severity: 'Severity Ranker',
    AgentName.action: 'Action Planner',
  };

  static const _icons = {
    AgentName.signal: Icons.wifi_tethering,
    AgentName.detection: Icons.radar,
    AgentName.severity: Icons.analytics_outlined,
    AgentName.action: Icons.task_alt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(widget.agent);
    final completed = widget.step?.isCompleted ?? false;
    final waiting =
        widget.step == null && !widget.isThinking;

    final borderColor = completed
        ? color.withOpacity(0.5)
        : widget.isThinking
            ? color.withOpacity(0.7)
            : AppColors.borderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: waiting
            ? AppColors.surfaceCard.withOpacity(0.4)
            : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: borderColor,
            width: widget.isThinking ? 1.5 : 1),
        boxShadow: widget.isThinking
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          // Gradient top bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.3)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: color.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Icon(
                          _icons[widget.agent] ?? Icons.circle,
                          size: 16,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.agent.name
                                    .toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (widget.step
                                      ?.usedMockFallback ??
                                  false) ...[
                                MonoText('[demo]',
                                    fontSize: 9,
                                    color:
                                        AppColors.textTertiary),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _roles[widget.agent] ?? '',
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _urduNames[widget.agent] ?? '',
                                style: GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    _StatusChip(
                      completed: completed,
                      isThinking: widget.isThinking,
                      waiting: waiting,
                      color: color,
                    ),
                    if (widget.step != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _expanded = !_expanded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Reasoning excerpt
                if (widget.isThinking)
                  Row(
                    children: [
                      AgentThinkingDots(color: color),
                      const SizedBox(width: 10),
                      Text(
                        'thinking…',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else if (widget.step != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                            color: color.withOpacity(0.5),
                            width: 3),
                      ),
                    ),
                    child: Text(
                      widget.step!.outputSummary,
                      style: GoogleFonts.instrumentSerif(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: _expanded ? 100 : 3,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    'Waiting for upstream agent…',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                // Exec time + Inspect
                if (widget.step != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MonoText(
                        '${widget.step!.durationMs}ms',
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(
                            () => _expanded = !_expanded),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: color
                                    .withOpacity(0.4)),
                          ),
                          child: MonoText(
                            _expanded
                                ? 'COLLAPSE'
                                : 'INSPECT',
                            fontSize: 9,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Expanded section
          if (_expanded && widget.step != null)
            _ExpandedSection(step: widget.step!),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * widget.index))
        .fadeIn(
          duration: 600.ms,
          curve: Cubic(0.32, 0.72, 0, 1),
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Cubic(0.32, 0.72, 0, 1),
        );
  }
}

class _StatusChip extends StatelessWidget {
  final bool completed;
  final bool isThinking;
  final bool waiting;
  final Color color;

  const _StatusChip({
    required this.completed,
    required this.isThinking,
    required this.waiting,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final label = completed
        ? 'COMPLETE'
        : isThinking
            ? 'RUNNING'
            : 'QUEUED';
    final chipColor = completed
        ? AppColors.low
        : isThinking
            ? color
            : AppColors.textTertiary;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: chipColor.withOpacity(0.4)),
      ),
      child: MonoText(
        label,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: chipColor,
      ),
    );
  }
}

class _ExpandedSection extends StatelessWidget {
  final AgentStep step;
  const _ExpandedSection({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INPUT', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(step.inputSummary,
              style: AppTypography.bodyMedium),
          const SizedBox(height: 12),
          Text('REASONING', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(step.reasoning,
              style: AppTypography.bodyMedium),
          const SizedBox(height: 12),
          Text('TOOLS USED', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: step.toolsUsed
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: MonoText(t,
                          fontSize: 10,
                          color: AppColors.textSecondary),
                    ))
                .toList(),
          ),
          if (step.usedMockFallback) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundBase,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MonoText(
                '// DEMO_MODE=true — mock response used\n// Real LLM call skipped',
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Handoff Line ──────────────────────────────────────────────────────────────

class _HandoffLine extends StatefulWidget {
  final AgentName from;
  final bool completed;

  const _HandoffLine({required this.from, required this.completed});

  @override
  State<_HandoffLine> createState() => _HandoffLineState();
}

class _HandoffLineState extends State<_HandoffLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.completed) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_HandoffLine old) {
    super.didUpdateWidget(old);
    if (widget.completed && !old.completed) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(widget.from);
    return SizedBox(
      height: 24,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: const Size(2, 24),
            painter: _HandoffPainter(
              progress: _ctrl.value,
              color: color.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _HandoffPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _HandoffPainter(
      {required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), bg);

    if (progress > 0) {
      final fg = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height * progress),
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_HandoffPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Completion bar ────────────────────────────────────────────────────────────

class _CompletionBar extends ConsumerWidget {
  final String crisisId;
  const _CompletionBar({required this.crisisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
            top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go('/crisis/$crisisId'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.borderSubtle),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('VIEW CRISIS',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Land on the Actions tab inside the persistent shell.
                ref.read(navIndexProvider.notifier).state = 2;
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('EXECUTE ACTIONS',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPipelineState extends StatelessWidget {
  const _EmptyPipelineState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Pipeline will appear here',
              style: AppTypography.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Enter a signal on the Home screen and tap RUN PIPELINE',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
