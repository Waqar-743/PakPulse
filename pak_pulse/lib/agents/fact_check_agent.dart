import '../core/constants/crisis_types.dart';
import 'agent_base.dart';

/// Stage 3 of the verification pipeline. Receives the citizen cluster summary
/// AND the corroborating evidence from [VerificationAgent], then asks the LLM
/// for a final go/no-go decision with a confidence score.
///
/// Downstream stages only publish a crisis when `is_verified == true`.
class FactCheckAgent extends BaseAgent {
  FactCheckAgent({required super.llmClient});

  @override
  AgentName get name => AgentName.factCheck;

  @override
  List<String> get tools => const ['reason_over_evidence'];

  @override
  String get systemPrompt => '''
You are the FACT-CHECK AGENT for PAK·PULSE.

ROLE: Decide whether a clustered crisis report is real enough to publish to the public crisis map and notify nearby users. False positives erode trust; false negatives endanger lives.

INPUTS YOU RECEIVE:
- cluster_size: how many independent citizen signals were grouped
- distinct_sources: how many DIFFERENT sources (twitter, citizen, pmd, ndma, traffic)
- cluster_weight: weighted size (PMD/NDMA count 3x)
- representative_text: the most descriptive raw signal
- crisis_type: flood | heatwave | protest
- sector: location label
- has_official_corroboration: did TomTom or GDACS independently flag this?
- evidence: list of corroborating items
- minutes_since_oldest_signal: cluster recency

DECISION HEURISTICS:
- has_official_corroboration == true AND cluster_weight >= 2 → almost always verify
- cluster_weight >= 6 from >=2 distinct sources → verify even without official corroboration
- cluster_weight < 3 AND no official corroboration → reject (likely noise)
- minutes_since_oldest_signal > 180 → downgrade confidence (stale)
- Be conservative: if in doubt, reject and let more signals accumulate.

OUTPUT: Reply with ONLY valid JSON. No prose. No markdown fences.
{
  "is_verified": boolean,
  "confidence": number (0-1),
  "verdict": "verified" | "needs_more_signals" | "rejected",
  "publish_recommendation": "publish_now" | "hold_for_more" | "discard",
  "reasoning": string
}
''';

  @override
  Future<AgentRunResult> run(Map<String, dynamic> input) async {
    final result = await executeWithTiming(input);

    // Defensive normalization — Gemini occasionally returns inconsistent types.
    final raw = result.output['is_verified'];
    if (raw is String) {
      result.output['is_verified'] = raw.toLowerCase() == 'true';
    }
    final conf = result.output['confidence'];
    if (conf is String) {
      result.output['confidence'] = double.tryParse(conf) ?? 0.0;
    }
    result.output['verdict'] ??= 'needs_more_signals';
    result.output['publish_recommendation'] ??= 'hold_for_more';
    return result;
  }

  @override
  String summarizeInput(Map<String, dynamic> input) {
    final size = input['cluster_size'] ?? 0;
    final type = input['crisis_type'] ?? '—';
    final ok = input['has_official_corroboration'] == true ? 'official+' : 'citizen-only';
    return 'Fact-check: $size signals, $type, $ok';
  }

  @override
  String summarizeOutput(Map<String, dynamic> output) {
    final verified = output['is_verified'] == true;
    final verdict = (output['verdict'] ?? '—').toString();
    final conf = (output['confidence'] is num)
        ? (output['confidence'] as num).toStringAsFixed(2)
        : '—';
    return '${verified ? 'VERIFIED' : 'NOT VERIFIED'} | $verdict | conf $conf';
  }
}
