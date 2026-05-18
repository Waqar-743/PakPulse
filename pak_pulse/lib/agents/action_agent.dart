import 'package:uuid/uuid.dart';

import '../core/constants/crisis_types.dart';
import '../data/models/crisis_action.dart';
import 'agent_base.dart';
import 'tools/alert_tool.dart';
import 'tools/reroute_tool.dart';
import 'tools/ticket_tool.dart';

const _uuid = Uuid();

class ActionAgentResult {
  final AgentRunResult agentResult;
  final List<CrisisAction> actions;

  const ActionAgentResult({required this.agentResult, required this.actions});
}

class ActionAgent extends BaseAgent {
  ActionAgent({required super.llmClient});

  @override
  AgentName get name => AgentName.action;

  @override
  List<String> get tools => const [
        'create_rescue_ticket',
        'compute_reroute',
        'draft_sms_alert',
      ];

  @override
  String get systemPrompt => '''
You are the ACTION AGENT for PAK·PULSE.

ROLE: Generate exactly 3 prioritized response actions for a confirmed crisis.

USE REAL AGENCY NAMES:
- Rescue 1122 (life safety, medical, fire)
- Islamabad Traffic Police / ITP (traffic, reroutes)
- NDMA / PDMA (mass alerts, disaster ops)
- Met Office / PMD (weather warnings)

USE REAL ROUTES (where applicable):
- 9th Avenue, Service Road Eastern, Murree Road, Margalla Road, Faizabad Interchange

PRIORITY ORDER:
1. Life safety (rescue dispatch, medical)
2. Traffic / infrastructure (reroute, road closure)
3. Public communication (SMS, broadcast)

OUTPUT: Reply with ONLY valid JSON. No prose. No markdown fences.
{
  "actions": [
    {
      "priority": 1|2|3,
      "type": "dispatch_rescue" | "traffic_reroute" | "citizen_alert_sms",
      "title": string,
      "description": string,
      "target_agency": string,
      "payload": object,
      "estimated_impact": string
    }
  ],
  "reasoning": string
}
''';

  @override
  Future<AgentRunResult> run(Map<String, dynamic> input) async {
    return executeWithTiming(input);
  }

  ActionAgentResult realizeActions({
    required AgentRunResult agentResult,
    required String sector,
    required String crisisType,
    required String severity,
  }) {
    final list = (agentResult.output['actions'] as List?) ?? const [];
    final realized = <CrisisAction>[];

    for (final raw in list) {
      final m = Map<String, dynamic>.from(raw as Map);
      final typeStr = (m['type'] ?? 'dispatch_rescue').toString();
      final (actionType, toolResponse, ticketId) = _runTool(
        typeStr: typeStr,
        sector: sector,
        crisisType: crisisType,
        severity: severity,
      );

      realized.add(CrisisAction(
        id: 'act_${_uuid.v4().substring(0, 8)}',
        type: actionType,
        status: ActionStatus.pending,
        title: (m['title'] ?? actionType.name.toUpperCase()).toString(),
        description: (m['description'] ?? '').toString(),
        targetAgency: (m['target_agency'] ?? '—').toString(),
        payload: Map<String, dynamic>.from(m['payload'] as Map? ?? const {}),
        mockTicketId: ticketId,
        mockResponse: _prettyJson(toolResponse),
      ));
    }

    return ActionAgentResult(agentResult: agentResult, actions: realized);
  }

  (ActionType, Map<String, dynamic>, String?) _runTool({
    required String typeStr,
    required String sector,
    required String crisisType,
    required String severity,
  }) {
    if (typeStr.contains('rescue') || typeStr.contains('dispatch')) {
      final resp = TicketTool.createRescueTicket(
        sector: sector,
        crisisType: crisisType,
      );
      return (ActionType.dispatch, resp, resp['ticket_id'] as String?);
    }
    if (typeStr.contains('reroute') || typeStr.contains('traffic')) {
      final plan = RerouteTool.computeReroute(sector: sector, crisisType: crisisType);
      final itp = TicketTool.createItpTicket(
        sector: sector,
        alternateRoute: plan.alternateRoute,
      );
      final merged = {...plan.response, 'itp_ticket_id': itp['ticket_id']};
      return (ActionType.reroute, merged, itp['ticket_id'] as String?);
    }
    if (typeStr.contains('alert') || typeStr.contains('sms') || typeStr.contains('broadcast')) {
      final ndma = TicketTool.createNdmaTicket(sector: sector, crisisType: crisisType);
      final sms = AlertTool.draftSms(
        sector: sector,
        crisisType: crisisType,
        severity: severity,
      );
      final merged = {...sms, 'ndma_ticket_id': ndma['ticket_id']};
      return (ActionType.alert, merged, ndma['ticket_id'] as String?);
    }
    final resp = TicketTool.createRescueTicket(sector: sector, crisisType: crisisType);
    return (ActionType.ticket, resp, resp['ticket_id'] as String?);
  }

  String _prettyJson(Map<String, dynamic> map) {
    final buf = StringBuffer('{\n');
    final entries = map.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      buf.write('  "${e.key}": ');
      buf.write(_encodeValue(e.value));
      if (i < entries.length - 1) buf.write(',');
      buf.write('\n');
    }
    buf.write('}');
    return buf.toString();
  }

  String _encodeValue(Object? v) {
    if (v == null) return 'null';
    if (v is num || v is bool) return v.toString();
    if (v is List) return '[${v.map(_encodeValue).join(', ')}]';
    if (v is Map) return '{...}';
    return '"${v.toString().replaceAll('"', r'\"')}"';
  }

  @override
  String summarizeInput(Map<String, dynamic> input) {
    final sev = (input['severity'] ?? '—').toString().toUpperCase();
    final type = (input['crisis_type'] ?? '—').toString();
    final sector = (input['sector'] ?? '—').toString();
    final rsi = input['rsi_score'] ?? '—';
    return '$sev $type @ $sector | RSI $rsi';
  }

  @override
  String summarizeOutput(Map<String, dynamic> output) {
    final actions = (output['actions'] as List?) ?? const [];
    if (actions.isEmpty) return 'No actions generated';
    final titles = actions
        .map((a) => (a as Map)['title']?.toString() ?? '—')
        .toList();
    return '${actions.length} actions: ${titles.join(' | ')}';
  }
}
