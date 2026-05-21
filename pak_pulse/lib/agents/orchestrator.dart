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
import 'fact_check_agent.dart';
import 'severity_agent.dart';
import 'signal_agent.dart';
import 'signal_clusterer.dart';
import 'verification_agent.dart';

const _uuid = Uuid();

enum OrchestratorPhase {
  agentStarted,
  agentCompleted,
  pipelineComplete,
  pipelineRejected,
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

  /// Cluster-aware verification pipeline. Used when 2+ citizen signals fuse
  /// into a single candidate event. Runs the full 6-agent chain:
  /// Signal → Detection → Verification → FactCheck → Severity → Action.
  /// Only publishes a crisis when the FactCheckAgent verifies it.
  Stream<OrchestratorEvent> runClusterPipeline(SignalCluster cluster) async* {
    final trace = <AgentStep>[];

    final signalAgent = SignalAgent(llmClient: llmClient);
    final detectionAgent = DetectionAgent(
      llmClient: llmClient,
      recentSignals: ref.read(signalListProvider),
      activeCrises: ref.read(crisisListProvider),
    );
    final verificationAgent = VerificationAgent(
      llmClient: llmClient,
      trafficService: ref.read(trafficServiceProvider),
      disasterNewsService: ref.read(disasterNewsServiceProvider),
    );
    final factCheckAgent = FactCheckAgent(llmClient: llmClient);
    final severityAgent = SeverityAgent(llmClient: llmClient);
    final actionAgent = ActionAgent(llmClient: llmClient);

    try {
      // 1. SIGNAL — normalize the representative report in the cluster.
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.signal,
        trace: List.unmodifiable(trace),
      );
      final signalResult =
          await signalAgent.run({'raw_text': cluster.representativeText});
      trace.add(signalResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.signal,
        step: signalResult.step,
        trace: List.unmodifiable(trace),
      );

      // Override the LLM's sector guess with the cluster's actual sector —
      // the cluster was already grouped by exact sector, so it's authoritative.
      signalResult.output['sector'] = cluster.sector;
      signalResult.output['crisis_hint'] = cluster.crisisType.name;

      // 2. DETECTION
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.detection,
        trace: List.unmodifiable(trace),
      );
      final detectionResult = await detectionAgent.run({
        'sector': cluster.sector,
        'crisis_hint': cluster.crisisType.name,
      });
      // Replace the LLM's signal count with the real cluster size.
      detectionResult.output['signal_count_in_cluster'] = cluster.size;
      trace.add(detectionResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.detection,
        step: detectionResult.step,
        trace: List.unmodifiable(trace),
      );

      // 3. VERIFICATION — pull TomTom + GDACS corroboration.
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.verification,
        trace: List.unmodifiable(trace),
      );
      final lat = (signalResult.output['lat_hint'] is num)
          ? (signalResult.output['lat_hint'] as num).toDouble()
          : 33.69;
      final lng = (signalResult.output['lng_hint'] is num)
          ? (signalResult.output['lng_hint'] as num).toDouble()
          : 73.0228;
      final verificationResult = await verificationAgent.run({
        'sector': cluster.sector,
        'crisis_type': cluster.crisisType.name,
        'cluster_size': cluster.size,
        'lat': lat,
        'lng': lng,
      });
      trace.add(verificationResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.verification,
        step: verificationResult.step,
        trace: List.unmodifiable(trace),
      );

      // 4. FACT-CHECK — final go/no-go.
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.factCheck,
        trace: List.unmodifiable(trace),
      );
      final oldestSignal = cluster.signals.reduce(
          (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);
      final factCheckResult = await factCheckAgent.run({
        'cluster_size': cluster.size,
        'distinct_sources': cluster.distinctSources,
        'cluster_weight': cluster.weight,
        'representative_text': cluster.representativeText,
        'crisis_type': cluster.crisisType.name,
        'sector': cluster.sector,
        'has_official_corroboration':
            verificationResult.output['has_official_corroboration'] == true,
        'evidence': verificationResult.output['evidence'] ?? const [],
        'minutes_since_oldest_signal':
            DateTime.now().difference(oldestSignal.timestamp).inMinutes,
      });
      trace.add(factCheckResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.factCheck,
        step: factCheckResult.step,
        trace: List.unmodifiable(trace),
      );

      // Hard gate: if fact-check says no, stop here. Don't compute severity
      // or actions for unverified events — that would just confuse responders.
      if (factCheckResult.output['is_verified'] != true) {
        yield OrchestratorEvent(
          phase: OrchestratorPhase.pipelineRejected,
          trace: List.unmodifiable(trace),
          errorMessage:
              (factCheckResult.output['reasoning'] ?? 'Rejected by fact-check')
                  .toString(),
        );
        return;
      }

      // 5. SEVERITY
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.severity,
        trace: List.unmodifiable(trace),
      );
      final severityResult = await severityAgent.run({
        'sector': cluster.sector,
        'crisis_type': cluster.crisisType.name,
        'signal_count_in_cluster': cluster.size,
      });
      trace.add(severityResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.severity,
        step: severityResult.step,
        trace: List.unmodifiable(trace),
      );

      // 6. ACTION
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentStarted,
        agent: AgentName.action,
        trace: List.unmodifiable(trace),
      );
      final actionRawResult = await actionAgent.run({
        'sector': cluster.sector,
        'crisis_type': cluster.crisisType.name,
        'severity': severityResult.output['severity'],
        'rsi_score': severityResult.output['rsi_score'],
      });
      final actionRealized = actionAgent.realizeActions(
        agentResult: actionRawResult,
        sector: cluster.sector,
        crisisType: cluster.crisisType.name,
        severity: (severityResult.output['severity'] ?? 'high').toString(),
      );
      trace.add(actionRawResult.step);
      yield OrchestratorEvent(
        phase: OrchestratorPhase.agentCompleted,
        agent: AgentName.action,
        step: actionRawResult.step,
        trace: List.unmodifiable(trace),
      );

      // Build verified crisis and publish.
      final crisis = _buildCrisis(
        signal: signalResult.output,
        detection: detectionResult.output,
        severity: severityResult.output,
        actions: actionRealized.actions,
        trace: trace,
        rawSignalText: cluster.representativeText,
      );

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
    await _drive(_orchestrator.runPipeline(rawSignalText));
  }

  /// Runs the cluster-aware verification pipeline. Use this when 2+ citizen
  /// signals have been grouped — only verified clusters are published.
  Future<void> runClusterPipeline(SignalCluster cluster) async {
    await _drive(_orchestrator.runClusterPipeline(cluster));
  }

  Future<void> _drive(Stream<OrchestratorEvent> stream) async {
    await _subscription?.cancel();
    state = const OrchestratorState(isRunning: true);

    final completer = Completer<void>();
    _subscription = stream.listen(
      (event) {
        final isTerminal = event.phase == OrchestratorPhase.pipelineComplete ||
            event.phase == OrchestratorPhase.pipelineRejected ||
            event.phase == OrchestratorPhase.failed;
        state = state.copyWith(
          events: [...state.events, event],
          isRunning: !isTerminal,
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
