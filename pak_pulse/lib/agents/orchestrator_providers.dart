import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/services/llm_client.dart';
import '../data/services/notification_service.dart';
import '../providers.dart';
import 'orchestrator.dart';
import 'signal_clusterer.dart';

const _autoVerifierUuid = Uuid();

final llmClientProvider = Provider<LlmClient>((ref) {
  // Rebuilds when the Settings "Demo Mode" toggle flips, so the pipeline
  // switches between live Gemini calls and offline mock responses instantly.
  return LlmClient(forceDemo: ref.watch(demoModeProvider));
});

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

// ── Signal clustering & auto-verification ────────────────────────────────────

final signalClustererProvider =
    Provider<SignalClusterer>((_) => const SignalClusterer());

/// Live list of citizen-signal clusters that currently qualify for the
/// verification pipeline (weight >= threshold, within the active window).
final qualifyingClustersProvider = Provider<List<SignalCluster>>((ref) {
  final signals = ref.watch(signalListProvider);
  final clusterer = ref.watch(signalClustererProvider);
  return clusterer.qualifyingClusters(signals);
});

/// Auto-verifier: watches qualifying clusters and fires the 6-agent
/// verification pipeline on any cluster we haven't already processed.
/// Activated by reading [autoVerifierProvider] from the widget tree (e.g.
/// the Home screen) — keeps the trigger explicit rather than always-on.
class AutoVerifier extends StateNotifier<Set<String>> {
  AutoVerifier(this._ref) : super(<String>{}) {
    _ref.listen<List<SignalCluster>>(qualifyingClustersProvider,
        (prev, next) => _onClusters(next),
        fireImmediately: true);
  }

  final Ref _ref;
  bool _running = false;

  String _signature(SignalCluster c) =>
      '${c.sector.toLowerCase()}|${c.crisisType.name}|${c.signals.length}';

  Future<void> _onClusters(List<SignalCluster> clusters) async {
    if (_running) return;
    for (final c in clusters) {
      final sig = _signature(c);
      if (state.contains(sig)) continue;
      // Skip clusters whose sector+type already has an active crisis on the
      // map — DetectionAgent would dedup anyway, but skipping saves a run.
      final active = _ref.read(crisisListProvider);
      final alreadyMapped = active.any((cr) =>
          cr.sector.toLowerCase() == c.sector.toLowerCase() &&
          cr.type == c.crisisType);
      if (alreadyMapped) {
        state = {...state, sig};
        continue;
      }
      _running = true;
      try {
        await _ref
            .read(orchestratorControllerProvider.notifier)
            .runClusterPipeline(c);
        _maybeNotify();
      } finally {
        _running = false;
        state = {...state, sig};
      }
      // Process one cluster per tick — the next listen fire picks up more.
      break;
    }
  }

  /// Called after a cluster pipeline run finishes. If the run produced a
  /// verified crisis near the user's stored location, push a notification.
  void _maybeNotify() {
    final completed =
        _ref.read(orchestratorControllerProvider).completedCrisis;
    if (completed == null) return;

    final user = _ref.read(userLocationProvider);
    if (user == null) return;

    final d = distanceKm(
      lat1: user.lat,
      lng1: user.lng,
      lat2: completed.lat,
      lng2: completed.lng,
    );
    if (d > 25.0) return; // beyond a reasonable city-wide radius

    // Don't duplicate notifications for the same crisis.
    final existing = _ref.read(notificationStoreProvider);
    if (existing.any((n) => n.crisis.id == completed.id)) return;

    _ref.read(notificationStoreProvider.notifier).push(
          CrisisNotification(
            id: 'notif_${_autoVerifierUuid.v4().substring(0, 8)}',
            crisis: completed,
            createdAt: DateTime.now(),
            distanceKm: d,
          ),
        );
  }
}

/// Holds the set of cluster signatures we've already processed. Reading this
/// provider from a widget activates the auto-verifier for the session.
final autoVerifierProvider =
    StateNotifierProvider<AutoVerifier, Set<String>>((ref) {
  return AutoVerifier(ref);
});
