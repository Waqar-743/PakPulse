import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/agent_colors.dart';
import '../core/constants/crisis_types.dart';
import '../data/models/agent_step.dart';
import '../data/services/llm_client.dart';

const _uuid = Uuid();

class AgentRunResult {
  final AgentStep step;
  final Map<String, dynamic> output;

  const AgentRunResult({required this.step, required this.output});
}

abstract class BaseAgent {
  BaseAgent({required this.llmClient});

  final LlmClient llmClient;

  AgentName get name;
  String get displayName => '${name.name.toUpperCase()} AGENT';
  Color get color => AgentColors.forAgent(name);

  String get systemPrompt;
  List<String> get tools => const [];

  Future<AgentRunResult> run(Map<String, dynamic> input);

  String summarizeInput(Map<String, dynamic> input);
  String summarizeOutput(Map<String, dynamic> output);

  Future<AgentRunResult> executeWithTiming(Map<String, dynamic> input) async {
    final stopwatch = Stopwatch()..start();
    final result = await llmClient.complete(
      systemPrompt: systemPrompt,
      input: input,
    );
    stopwatch.stop();

    final step = AgentStep(
      id: 'step_${_uuid.v4().substring(0, 8)}',
      agentName: name,
      timestamp: DateTime.now(),
      inputSummary: summarizeInput(input),
      outputSummary: summarizeOutput(result.json),
      reasoning: (result.json['reasoning'] ?? '').toString(),
      toolsUsed: tools,
      durationMs: stopwatch.elapsedMilliseconds,
      isCompleted: true,
      usedMockFallback: result.usedMockFallback,
    );

    return AgentRunResult(step: step, output: result.json);
  }
}
