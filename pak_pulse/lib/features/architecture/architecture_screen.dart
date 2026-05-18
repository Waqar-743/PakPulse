import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/agent_colors.dart';
import '../../core/constants/crisis_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/atoms/mono_text.dart';

class ArchitectureScreen extends StatelessWidget {
  const ArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          'ARCHITECTURE',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            label: 'CHALLENGE',
            child: _MonoBlock(
              text: 'Google Antigravity Hackathon\nChallenge 3 — CIRO',
            ),
          ),
          SizedBox(height: 24),
          _Section(
            label: 'APP',
            child: _MonoBlock(
              text:
                  'PAK·PULSE\nCrisis Intelligence & Response Orchestrator\nPlatform: Flutter (Android + iOS)\nLanguages: English · Urdu · Roman Urdu',
            ),
          ),
          SizedBox(height: 24),
          _Section(
            label: 'AGENT PIPELINE',
            child: _AgentDiagram(),
          ),
          SizedBox(height: 24),
          _Section(
            label: 'TECH STACK',
            child: _StackList(items: [
              ('Riverpod', 'state management'),
              ('go_router', 'navigation'),
              ('flutter_map', 'map + tile cache'),
              ('flutter_animate', 'declarative animations'),
              ('animations', 'shared-axis transitions'),
              ('dio + http', 'LLM client'),
              ('flutter_dotenv', '.env config'),
              ('google_fonts', 'Plus Jakarta + JetBrains Mono + Noto Nastaliq'),
              ('shimmer', 'skeleton loaders'),
              ('shared_preferences', 'onboarding flag'),
              ('uuid', 'agent step IDs'),
            ]),
          ),
          SizedBox(height: 24),
          _Section(
            label: 'TOOLS (mocked)',
            child: _StackList(items: [
              ('GeocodingTool', 'normalize + sector → LatLng'),
              ('TicketTool', 'Rescue 1122 / ITP / NDMA tickets'),
              ('RerouteTool', 'before/after polylines'),
              ('AlertTool', 'bilingual SMS drafts'),
            ]),
          ),
          SizedBox(height: 24),
          _Section(
            label: 'DESIGN PRINCIPLES',
            child: _MonoBlock(
              text:
                  '· Mock-first — never crashes\n· Urdu is a first-class language\n· Numbers always JetBrains Mono\n· Every step traceable\n· Demo-ready in airplane mode',
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _MonoBlock extends StatelessWidget {
  final String text;
  const _MonoBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: MonoText(text, fontSize: 12, color: AppColors.textPrimary),
    );
  }
}

class _StackList extends StatelessWidget {
  final List<(String, String)> items;
  const _StackList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: MonoText(row.$1,
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                      Expanded(
                        child: Text(row.$2, style: AppTypography.bodyMedium),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _AgentDiagram extends StatelessWidget {
  const _AgentDiagram();

  @override
  Widget build(BuildContext context) {
    final agents = [
      (AgentName.signal, 'S'),
      (AgentName.detection, 'D'),
      (AgentName.severity, 'Sv'),
      (AgentName.action, 'A'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < agents.length; i++) ...[
                _AgentBubble(agent: agents[i].$1, letter: agents[i].$2),
                if (i < agents.length - 1)
                  const _Arrow(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          MonoText(
            'raw → signal → cluster → severity → 3 actions',
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _AgentBubble extends StatelessWidget {
  final AgentName agent;
  final String letter;
  const _AgentBubble({required this.agent, required this.letter});

  @override
  Widget build(BuildContext context) {
    final color = AgentColors.forAgent(agent);
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(agent.name.toUpperCase(), style: AppTypography.labelSmall),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward,
          size: 16, color: AppColors.textTertiary),
    );
  }
}
