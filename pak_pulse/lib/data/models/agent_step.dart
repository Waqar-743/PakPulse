import '../../core/constants/crisis_types.dart';

class AgentStep {
  final String id;
  final AgentName agentName;
  final DateTime timestamp;
  final String inputSummary;
  final String outputSummary;
  final String reasoning;
  final List<String> toolsUsed;
  final int durationMs;
  final bool isCompleted;
  final bool usedMockFallback;

  const AgentStep({
    required this.id,
    required this.agentName,
    required this.timestamp,
    required this.inputSummary,
    required this.outputSummary,
    required this.reasoning,
    required this.toolsUsed,
    required this.durationMs,
    this.isCompleted = false,
    this.usedMockFallback = false,
  });

  factory AgentStep.fromJson(Map<String, dynamic> j) => AgentStep(
        id: j['id'] as String,
        agentName: AgentName.values.byName(j['agentName'] as String),
        timestamp: DateTime.parse(j['timestamp'] as String),
        inputSummary: j['inputSummary'] as String,
        outputSummary: j['outputSummary'] as String,
        reasoning: j['reasoning'] as String,
        toolsUsed: List<String>.from(j['toolsUsed'] as List),
        durationMs: j['durationMs'] as int,
        isCompleted: j['isCompleted'] as bool? ?? false,
        usedMockFallback: j['usedMockFallback'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'agentName': agentName.name,
        'timestamp': timestamp.toIso8601String(),
        'inputSummary': inputSummary,
        'outputSummary': outputSummary,
        'reasoning': reasoning,
        'toolsUsed': toolsUsed,
        'durationMs': durationMs,
        'isCompleted': isCompleted,
        'usedMockFallback': usedMockFallback,
      };

  AgentStep copyWith({
    String? id,
    AgentName? agentName,
    DateTime? timestamp,
    String? inputSummary,
    String? outputSummary,
    String? reasoning,
    List<String>? toolsUsed,
    int? durationMs,
    bool? isCompleted,
    bool? usedMockFallback,
  }) =>
      AgentStep(
        id: id ?? this.id,
        agentName: agentName ?? this.agentName,
        timestamp: timestamp ?? this.timestamp,
        inputSummary: inputSummary ?? this.inputSummary,
        outputSummary: outputSummary ?? this.outputSummary,
        reasoning: reasoning ?? this.reasoning,
        toolsUsed: toolsUsed ?? this.toolsUsed,
        durationMs: durationMs ?? this.durationMs,
        isCompleted: isCompleted ?? this.isCompleted,
        usedMockFallback: usedMockFallback ?? this.usedMockFallback,
      );
}
