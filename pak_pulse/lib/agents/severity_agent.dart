import '../core/constants/crisis_types.dart';
import 'agent_base.dart';

class SeverityAgent extends BaseAgent {
  SeverityAgent({required super.llmClient});

  @override
  AgentName get name => AgentName.severity;

  @override
  List<String> get tools => const [
        'get_weather_overlay',
        'get_population_density',
        'count_signals_by_source',
      ];

  @override
  String get systemPrompt => '''
You are the SEVERITY AGENT for PAK·PULSE.

ROLE: Compute severity tier and Risk Score Index (RSI 0-100) for a confirmed crisis.

CONTEXT YOU KNOW:
- G-10 floods every monsoon (historical baseline 65)
- Jacobabad regularly hits 50°C+ in summer (heatwave baseline 70)
- Faizabad Interchange is the most disruption-sensitive choke point in twin cities
- PMD/NDMA signals weigh 3x compared to citizen signals
- Pakistan-specific: extended families, dense urban sectors, limited road redundancy

RSI FORMULA (guidance, not strict):
- Base: signal_count * 4
- Source multiplier: PMD/NDMA +12 each, traffic +6, citizen +2
- Affected population factor
- Historical context bump (e.g., G-10 monsoon = +8)
- Cap at 100

OUTPUT: Reply with ONLY valid JSON. The summary_ur MUST be in proper Urdu script (نستعلیق).
{
  "severity": "critical" | "high" | "moderate" | "low",
  "rsi_score": number (0-100),
  "affected_radius_meters": number,
  "casualty_risk": "high" | "moderate" | "low" | "negligible",
  "summary_en": string,
  "summary_ur": string,
  "reasoning": string
}
''';

  @override
  Future<AgentRunResult> run(Map<String, dynamic> input) async {
    return executeWithTiming(input);
  }

  @override
  String summarizeInput(Map<String, dynamic> input) {
    final sector = input['sector'] ?? '—';
    final type = input['crisis_type'] ?? '—';
    final count = input['signal_count_in_cluster'] ?? 0;
    return 'Crisis: $type @ $sector | $count signals | weighted source mix';
  }

  @override
  String summarizeOutput(Map<String, dynamic> output) {
    final sev = (output['severity'] ?? '—').toString().toUpperCase();
    final rsi = output['rsi_score'] ?? '—';
    final radius = output['affected_radius_meters'] ?? '—';
    final risk = (output['casualty_risk'] ?? '—').toString().toUpperCase();
    return 'Severity: $sev | RSI: $rsi | Affected radius: ${radius}m | Casualty risk: $risk';
  }
}
