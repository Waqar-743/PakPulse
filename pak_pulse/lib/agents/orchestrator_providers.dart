import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/llm_client.dart';
import 'orchestrator.dart';

final llmClientProvider = Provider<LlmClient>((_) => LlmClient());

final orchestratorProvider = Provider<Orchestrator>((ref) {
  return Orchestrator(
    llmClient: ref.watch(llmClientProvider),
    ref: ref,
  );
});

final orchestratorControllerProvider =
    StateNotifierProvider<OrchestratorController, OrchestratorState>((ref) {
  return OrchestratorController(ref.watch(orchestratorProvider));
});
