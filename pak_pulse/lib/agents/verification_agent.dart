import 'package:uuid/uuid.dart';

import '../core/constants/crisis_types.dart';
import '../data/models/agent_step.dart';
import '../data/models/disaster_news.dart';
import '../data/models/road_incident.dart';
import '../data/services/disaster_news_service.dart';
import '../data/services/traffic_service.dart';
import 'agent_base.dart';

const _uuid = Uuid();

/// Stage 2 of the verification pipeline. Cross-checks a clustered citizen
/// signal against authoritative live feeds (TomTom traffic incidents +
/// GDACS disaster events). This agent does NOT call the LLM — it gathers
/// hard evidence that the next stage (FactCheckAgent) reasons over.
class VerificationAgent extends BaseAgent {
  VerificationAgent({
    required super.llmClient,
    required this.trafficService,
    required this.disasterNewsService,
  });

  final TrafficService trafficService;
  final DisasterNewsService disasterNewsService;

  @override
  AgentName get name => AgentName.verification;

  @override
  List<String> get tools => const ['tomtom_traffic', 'gdacs_disasters'];

  // Not used — this agent doesn't go to the LLM. Kept to satisfy BaseAgent.
  @override
  String get systemPrompt => '';

  @override
  Future<AgentRunResult> run(Map<String, dynamic> input) async {
    final stopwatch = Stopwatch()..start();

    final crisisTypeStr = (input['crisis_type'] ?? 'flood').toString();
    final crisisType = CrisisType.values.firstWhere(
      (t) => t.name == crisisTypeStr,
      orElse: () => CrisisType.flood,
    );
    final lat = (input['lat'] is num) ? (input['lat'] as num).toDouble() : 33.69;
    final lng =
        (input['lng'] is num) ? (input['lng'] as num).toDouble() : 73.0228;
    final sector = (input['sector'] ?? '').toString();

    // Run both lookups in parallel — they are independent.
    final results = await Future.wait([
      trafficService.fetchIncidents(lat: lat, lng: lng),
      disasterNewsService.fetchEvents(),
    ]);
    final incidents = results[0] as List<RoadIncident>;
    final disasters = results[1] as List<DisasterNews>;

    final corroboratingIncidents = _matchIncidents(crisisType, incidents);
    final corroboratingDisasters = _matchDisasters(crisisType, disasters);

    final hasOfficialCorroboration =
        corroboratingIncidents.isNotEmpty || corroboratingDisasters.isNotEmpty;

    final output = <String, dynamic>{
      'sector': sector,
      'crisis_type': crisisType.name,
      'tomtom_match_count': corroboratingIncidents.length,
      'gdacs_match_count': corroboratingDisasters.length,
      'has_official_corroboration': hasOfficialCorroboration,
      'evidence': [
        ...corroboratingIncidents.map((i) => {
              'source': 'tomtom',
              'label': i.categoryLabel,
              'from': i.from,
              'to': i.to,
              'delay_seconds': i.delaySeconds,
              'is_blockage': i.isBlockage,
            }),
        ...corroboratingDisasters.map((d) => {
              'source': 'gdacs',
              'event_type': d.eventType,
              'title': d.title,
              'country': d.country,
              'alert_level': d.alertLevel,
            }),
      ],
      'reasoning': hasOfficialCorroboration
          ? 'Citizen cluster matches ${corroboratingIncidents.length} TomTom incident(s) and ${corroboratingDisasters.length} GDACS event(s).'
          : 'No authoritative source currently corroborates this cluster — relying on citizen weight alone.',
    };

    stopwatch.stop();

    final step = AgentStep(
      id: 'step_${_uuid.v4().substring(0, 8)}',
      agentName: name,
      timestamp: DateTime.now(),
      inputSummary: summarizeInput(input),
      outputSummary: summarizeOutput(output),
      reasoning: (output['reasoning'] ?? '').toString(),
      toolsUsed: tools,
      durationMs: stopwatch.elapsedMilliseconds,
      isCompleted: true,
      usedMockFallback: false,
    );

    return AgentRunResult(step: step, output: output);
  }

  List<RoadIncident> _matchIncidents(
      CrisisType type, List<RoadIncident> incidents) {
    return incidents.where((i) {
      switch (type) {
        case CrisisType.protest:
          // Closures and lane closures match road-blockage clusters directly.
          return i.isBlockage || i.iconCategory == 6; // 6 = traffic jam
        case CrisisType.flood:
          return i.iconCategory == 11 || // flooding
              i.description.toLowerCase().contains('flood') ||
              i.description.toLowerCase().contains('water');
        case CrisisType.heatwave:
          return false; // traffic feed has no heat signal
      }
    }).toList();
  }

  List<DisasterNews> _matchDisasters(
      CrisisType type, List<DisasterNews> events) {
    final regional = events.where((e) => e.isRegional).toList();
    return regional.where((e) {
      final t = e.eventType.toUpperCase();
      switch (type) {
        case CrisisType.flood:
          // GDACS uses FL for floods, TC for tropical cyclones.
          return t == 'FL' || t == 'TC' || e.isFlood;
        case CrisisType.heatwave:
          // GDACS doesn't formally code heatwaves; match the title.
          return e.title.toLowerCase().contains('heat');
        case CrisisType.protest:
          return false;
      }
    }).toList();
  }

  @override
  String summarizeInput(Map<String, dynamic> input) {
    final sector = (input['sector'] ?? '—').toString();
    final type = (input['crisis_type'] ?? '—').toString();
    final count = input['cluster_size'] ?? 0;
    return 'Verifying $count-signal cluster: $type @ $sector';
  }

  @override
  String summarizeOutput(Map<String, dynamic> output) {
    final tt = output['tomtom_match_count'] ?? 0;
    final gd = output['gdacs_match_count'] ?? 0;
    final ok = output['has_official_corroboration'] == true;
    final label = ok ? 'CORROBORATED' : 'No official match';
    return '$label | TomTom: $tt | GDACS: $gd';
  }
}
