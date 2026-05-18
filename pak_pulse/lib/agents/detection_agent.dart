import '../core/constants/crisis_types.dart';
import '../data/models/crisis.dart';
import '../data/models/crisis_signal.dart';
import 'agent_base.dart';

class DetectionAgent extends BaseAgent {
  DetectionAgent({
    required super.llmClient,
    required this.recentSignals,
    required this.activeCrises,
  });

  final List<CrisisSignal> recentSignals;
  final List<Crisis> activeCrises;

  @override
  AgentName get name => AgentName.detection;

  @override
  List<String> get tools => const ['get_recent_signals', 'get_active_crises'];

  @override
  String get systemPrompt => '''
You are the DETECTION AGENT for PAK·PULSE.

ROLE: Decide whether an incoming signal indicates a NEW crisis or belongs to an EXISTING cluster.

DECISION RULES:
- Threshold for NEW crisis: 3+ signals from same sector within a 2-hour window
- A PMD or NDMA official source counts as 3 signals (3x weight)
- Existing crises are clustered by sector + crisis type
- If the signal matches an active crisis sector and type → existing cluster
- Otherwise → new crisis

OUTPUT: Reply with ONLY valid JSON. No prose. No markdown fences.
{
  "is_new_crisis": boolean,
  "crisis_type": "flood" | "heatwave" | "protest",
  "cluster_id": string,
  "signal_count_in_cluster": number,
  "confidence": number (0-1),
  "reasoning": string
}
''';

  @override
  Future<AgentRunResult> run(Map<String, dynamic> input) async {
    final sector = (input['sector'] ?? '').toString();
    final crisisHint = (input['crisis_hint'] ?? 'flood').toString();

    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    final clusterSignals = recentSignals
        .where((s) =>
            (s.sector ?? '').toLowerCase() == sector.toLowerCase() &&
            s.timestamp.isAfter(twoHoursAgo))
        .toList();

    final matchedCrisis = activeCrises.cast<Crisis?>().firstWhere(
          (c) => c != null && c.sector.toLowerCase() == sector.toLowerCase() && c.type.name == crisisHint,
          orElse: () => null,
        );

    final llmInput = {
      'sector': sector,
      'crisis_hint': crisisHint,
      'cluster_signal_count': clusterSignals.length,
      'active_crisis_match': matchedCrisis?.id,
    };

    final result = await executeWithTiming(llmInput);

    // Augment output with tool-derived facts
    result.output['signal_count_in_cluster'] ??= clusterSignals.length + 1;
    if (matchedCrisis != null) {
      result.output['is_new_crisis'] = false;
      result.output['cluster_id'] = matchedCrisis.id;
    }
    result.output['crisis_type'] ??= crisisHint;
    return result;
  }

  @override
  String summarizeInput(Map<String, dynamic> input) {
    final count = input['cluster_signal_count'] ?? 0;
    final sector = input['sector'] ?? '—';
    return '$count signals from $sector in last 2 hours';
  }

  @override
  String summarizeOutput(Map<String, dynamic> output) {
    final isNew = output['is_new_crisis'] == true;
    final type = (output['crisis_type'] ?? '—').toString();
    final cluster = (output['cluster_id'] ?? '—').toString();
    final count = output['signal_count_in_cluster'] ?? 0;
    final label = isNew ? 'NEW CRISIS confirmed' : 'EXISTING cluster';
    return '$label | Type: $type | Cluster: $cluster | Signals: $count';
  }
}
