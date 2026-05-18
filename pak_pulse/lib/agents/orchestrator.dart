import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/crisis_types.dart';
import '../data/models/agent_step.dart';
import '../data/models/crisis.dart';
import '../data/models/crisis_action.dart';
import '../data/services/llm_client.dart';
import '../providers.dart';
import 'action_agent.dart';
import 'detection_agent.dart';
import 'severity_agent.dart';
import 'signal_agent.dart';

const _uuid = Uuid();

enum OrchestratorPhase {
  agentStarted,
  agentCompleted,
  pipelineComplete,
  failed,
}

class OrchestratorEvent {
  final OrchestratorPhase phase;
  final AgentName? agent;
  final AgentStep? step;
  final Crisis? crisis;
  final List<AgentStep> trace;
  final String? errorMessage;

  const OrchestratorEvent({
    required this.phase,
    required this.trace,
    this.agent,
    this.step,
    this.crisis,
    this.errorMessage,
  });
}

class Orchestrator {
  Orchestrator({required this.llmClient, required this.ref});

  final LlmClient llmClient;
  final Ref ref;

  Stream<OrchestratorEvent> runPipeline(String rawSignalText) async* {
    final trace = <AgentStep>[];

    final signalAgent = SignalAgent(llmClient: llmClient);
    final detectionAgent = DetectionAgent(
      llmClient: llmClient,
      recentSignals: ref.read(signalListProvider),
      activeCrises: ref.read(crisisListProvider),
    );
    final severityAgent = SeverityAgent(llmClient: llmClient);
    final actionAgent = ActionAgent(llmClient: llmClient);

    try {
      // 1. SIGNAL AGENT
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.signal,
        trace: List.unmodifiable(trace),
      );
      final signalResult = await signalAgent.run({'raw_text': rawSignalText});
      trace.add(signalResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.signal,
        step: signalResult.step,
        trace: List.unmodifiable(trace),
      );

      // 2. DETECTION AGENT
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.detection,
        trace: List.unmodifiable(trace),
      );
      final detectionResult = await detectionAgent.run({
        'sector': signalResult.output['sector'],
        'crisis_hint': signalResult.output['crisis_hint'],
      });
      trace.add(detectionResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.detection,
        step: detectionResult.step,
        trace: List.unmodifiable(trace),
      );

      // 3. SEVERITY AGENT
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.severity,
        trace: List.unmodifiable(trace),
      );
      final severityResult = await severityAgent.run({
        'sector': signalResult.output['sector'],
        'crisis_type': detectionResult.output['crisis_type'],
        'signal_count_in_cluster':
            detectionResult.output['signal_count_in_cluster'],
      });
      trace.add(severityResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.severity,
        step: severityResult.step,
        trace: List.unmodifiable(trace),
      );

      // 4. ACTION AGENT
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.action,
        trace: List.unmodifiable(trace),
      );
      final actionRawResult = await actionAgent.run({
        'sector': signalResult.output['sector'],
        'crisis_type': detectionResult.output['crisis_type'],
        'severity': severityResult.output['severity'],
        'rsi_score': severityResult.output['rsi_score'],
      });
      final actionRealized = actionAgent.realizeActions(
        agentResult: actionRawResult,
        sector: (signalResult.output['sector'] ?? 'G-10 Markaz').toString(),
        crisisType:
            (detectionResult.output['crisis_type'] ?? 'flood').toString(),
        severity: (severityResult.output['severity'] ?? 'high').toString(),
      );
      trace.add(actionRawResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.action,
        step: actionRawResult.step,
        trace: List.unmodifiable(trace),
      );

      // Build crisis object
      final crisis = _buildCrisis(
        signal: signalResult.output,
        detection: detectionResult.output,
        severity: severityResult.output,
        actions: actionRealized.actions,
        trace: trace,
        rawSignalText: rawSignalText,
      );

      // Register crisis with global state (if new)
      if (detectionResult.output['is_new_crisis'] == true) {
        ref.read(crisisListProvider.notifier).addCrisis(crisis);
      }

      yield OrchestratorEvent(
        phase: OrchestratorPhase.pipelineComplete,
        trace: List.unmodifiable(trace),
        crisis: crisis,
      );
    } catch (e) {
      yield OrchestratorEvent(
        phase: OrchestratorPhase.failed,
        trace: List.unmodifiable(trace),
        errorMessage: e.toString(),
      );
    }
  }

  Crisis _buildCrisis({
    required Map<String, dynamic> signal,
    required Map<String, dynamic> detection,
    required Map<String, dynamic> severity,
    required List<CrisisAction> actions,
    required List<AgentStep> trace,
    required String rawSignalText,
  }) {
    final typeStr = (detection['crisis_type'] ?? 'flood').toString();
    final type = CrisisType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => CrisisType.flood,
    );
    final severityStr = (severity['severity'] ?? 'high').toString();
    final sev = SeverityLevel.values.firstWhere(
      (s) => s.name == severityStr,
      orElse: () => SeverityLevel.high,
    );
    final sector = (signal['sector'] ?? 'G-10 Markaz').toString();
    final lat = (signal['lat_hint'] is num) ? (signal['lat_hint'] as num).toDouble() : 33.69;
    final lng = (signal['lng_hint'] is num) ? (signal['lng_hint'] as num).toDouble() : 73.0228;

    final id = (detection['cluster_id'] ?? 'crisis_live_${_uuid.v4().substring(0, 6)}').toString();

    return Crisis(
      id: id,
      type: type,
      title: '${type.label} — $sector',
      sector: sector,
      lat: lat,
      lng: lng,
      severity: sev,
      confidence: ((severity['confidence'] ??
              detection['confidence'] ??
              signal['confidence'] ??
              0.85) as num)
          .toDouble(),
      riskScore: (severity['rsi_score'] is num) ? (severity['rsi_score'] as num).toInt() : 70,
      detectedAt: DateTime.now(),
      affectedRadiusMeters: (severity['affected_radius_meters'] is num)
          ? (severity['affected_radius_meters'] as num).toInt()
          : 800,
      summaryEn: (severity['summary_en'] ?? 'Crisis confirmed by pipeline.').toString(),
      summaryUr: (severity['summary_ur'] ?? 'بحران کی تصدیق ہو گئی ہے۔').toString(),
      signalCount: (detection['signal_count_in_cluster'] is num)
          ? (detection['signal_count_in_cluster'] as num).toInt()
          : 1,
      signalIds: ['live_${_uuid.v4().substring(0, 6)}'],
      actions: actions,
      reasoning: trace,
      isActive: true,
    );
  }
}

// ── State & Provider ─────────────────────────────────────────────────────────

class OrchestratorState {
  final List<OrchestratorEvent> events;
  final bool isRunning;
  final Crisis? completedCrisis;

  const OrchestratorState({
    this.events = const [],
    this.isRunning = false,
    this.completedCrisis,
  });

  List<AgentStep> get trace =>
      events.isEmpty ? const [] : events.last.trace;

  OrchestratorState copyWith({
    List<OrchestratorEvent>? events,
    bool? isRunning,
    Crisis? completedCrisis,
  }) =>
      OrchestratorState(
        events: events ?? this.events,
        isRunning: isRunning ?? this.isRunning,
        completedCrisis: completedCrisis ?? this.completedCrisis,
      );
}

class OrchestratorController extends StateNotifier<OrchestratorState> {
  OrchestratorController(this._orchestrator) : super(const OrchestratorState());

  final Orchestrator _orchestrator;
  StreamSubscription<OrchestratorEvent>? _subscription;

  Future<void> runPipeline(String rawSignalText) async {
    await _subscription?.cancel();
    state = const OrchestratorState(isRunning: true);

    final completer = Completer<void>();
    _subscription = _orchestrator.runPipeline(rawSignalText).listen(
      (event) {
        state = state.copyWith(
          events: [...state.events, event],
          isRunning: event.phase != OrchestratorPhase.pipelineComplete &&
              event.phase != OrchestratorPhase.failed,
          completedCrisis: event.crisis ?? state.completedCrisis,
        );
      },
      onDone: () {
        state = state.copyWith(isRunning: false);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_) {
        state = state.copyWith(isRunning: false);
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  void reset() {
    _subscription?.cancel();
    state = const OrchestratorState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
