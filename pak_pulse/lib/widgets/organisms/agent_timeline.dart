import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/agent_step.dart';
import '../atoms/agent_thinking_dots.dart';
import '../atoms/mono_text.dart';
import '../atoms/shimmer_skeleton.dart';

class AgentTimeline extends StatelessWidget {
  final List<AgentStep> steps;
  final bool isLoading;

  const AgentTimeline({
    super.key,
    required this.steps,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _TimelineSkeleton();

    final ordered = _orderedAgents
        .map((name) {
          try {
            return steps.firstWhere((s) => s.agentName == name);
          } catch (_) {
            return null;
          }
        })
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordered.length,
      itemBuilder: (_, i) {
        final step = ordered[i];
        return Column(
          children: [
            if (step != null)
              _AgentStepCard(step: step)
            else
              _WaitingCard(agent: _orderedAgents[i]),
            if (i < ordered.length - 1)
              _HandoffLine(
                from: _orderedAgents[i],
                completed: step?.isCompleted ?? false,
              ),
          ],
        );
      },
    );
  }

  static const _orderedAgents = [
    AgentName.signal,
    AgentName.detection,
    AgentName.severity,
    AgentName.action,
  ];
}

class _AgentStepCard extends StatefulWidget {
  final AgentStep step;
  const _AgentStepCard({required this.step});

  @override
  State<_AgentStepCard> createState() => _AgentStepCardState();
}

class _AgentStepCardState extends State<_AgentStepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(widget.step.agentName);
    final agentLabel = widget.step.agentName.name.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.step.isCompleted
              ? color.withOpacity(0.4)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _AgentAvatar(
                  agent: widget.step.agentName,
                  completed: widget.step.isCompleted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(agentLabel,
                              style: AppTypography.headingSmall
                                  .copyWith(fontSize: 13, color: color)),
                          const SizedBox(width: 8),
                          Text('AGENT',
                              style: AppTypography.labelSmall),
                          if (widget.step.usedMockFallback) ...[
                            const SizedBox(width: 6),
                            MonoText('[demo]',
                                fontSize: 9,
                                color: AppColors.textTertiary),
                          ],
                          const Spacer(),
                          MonoText(
                            '${widget.step.durationMs}ms',
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(widget.step.outputSummary,
                          style: AppTypography.bodyMedium,
                          maxLines: _expanded ? 100 : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded)
            _ExpandedSection(step: widget.step),
        ],
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
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INPUT', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(step.inputSummary, style: AppTypography.bodyMedium),
          const SizedBox(height: 12),
          Text('REASONING', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(step.reasoning,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary)),
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: MonoText(t, fontSize: 10,
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
                '// DEMO_MODE=true — mock response used\n// Real LLM call skipped (no API key)',
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

class _WaitingCard extends StatelessWidget {
  final AgentName agent;
  const _WaitingCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(agent);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _AgentAvatar(agent: agent, completed: false, dim: true),
          const SizedBox(width: 12),
          Text(
            '${agent.name.toUpperCase()} AGENT',
            style: AppTypography.bodyMedium,
          ),
          const Spacer(),
          AgentThinkingDots(color: color.withOpacity(0.4)),
        ],
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  final AgentName agent;
  final bool completed;
  final bool dim;

  const _AgentAvatar({
    required this.agent,
    required this.completed,
    this.dim = false,
  });

  static const _initials = {
    AgentName.signal: 'S',
    AgentName.detection: 'D',
    AgentName.severity: 'Sv',
    AgentName.action: 'A',
  };

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(agent);
    final opacity = dim ? 0.4 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15 * opacity),
            border: Border.all(
              color: color.withOpacity(0.6 * opacity),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _initials[agent] ?? agent.name[0].toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(opacity),
              ),
            ),
          ),
        ),
        if (completed)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.low,
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _HandoffLine extends StatelessWidget {
  final AgentName from;
  final bool completed;

  const _HandoffLine({required this.from, required this.completed});

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AgentColors.forAgent(from).withOpacity(0.6)
        : AppColors.borderSubtle;

    return Container(
      height: 24,
      alignment: Alignment.center,
      child: Container(
        width: 1.5,
        color: color,
      ),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: ShimmerSkeleton(width: 40, height: 40, radius: 20),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerSkeleton(
                            width: 80, height: 10, radius: 4),
                        SizedBox(height: 8),
                        ShimmerSkeleton(
                            width: double.infinity, height: 10, radius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
