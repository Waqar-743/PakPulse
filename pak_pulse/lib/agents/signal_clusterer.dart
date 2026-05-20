import '../core/constants/crisis_types.dart';
import '../data/models/crisis_signal.dart';

/// A fused group of recent signals that probably describe the same event.
class SignalCluster {
  final String sector;
  final CrisisType crisisType;
  final List<CrisisSignal> signals;

  const SignalCluster({
    required this.sector,
    required this.crisisType,
    required this.signals,
  });

  int get size => signals.length;

  /// Source diversity matters more than raw count — 5 tweets from 1 account
  /// is weaker than 2 reports from different sources.
  int get distinctSources => signals.map((s) => s.source).toSet().length;

  /// Weighted score used to decide whether to fire the verification pipeline.
  /// Official sources (PMD/NDMA) carry 3x weight.
  double get weight {
    double w = 0;
    for (final s in signals) {
      w += (s.source == SignalSource.pmd || s.source == SignalSource.ndma)
          ? 3.0
          : 1.0;
    }
    return w;
  }

  /// Representative raw text for prompts (longest is usually most informative).
  String get representativeText {
    final sorted = [...signals]
      ..sort((a, b) => b.rawText.length.compareTo(a.rawText.length));
    return sorted.first.rawText;
  }
}

/// Groups recent unprocessed signals into clusters by sector + crisis type
/// within a sliding time window. A cluster qualifies for the verification
/// pipeline when it meets the minimum weight threshold.
class SignalClusterer {
  const SignalClusterer({
    this.window = const Duration(hours: 2),
    this.minWeight = 2.0,
  });

  /// How far back to look when forming clusters.
  final Duration window;

  /// Minimum [SignalCluster.weight] required for a cluster to be "actionable".
  final double minWeight;

  /// Returns all clusters that meet the [minWeight] threshold, newest first.
  List<SignalCluster> qualifyingClusters(List<CrisisSignal> signals) {
    final cutoff = DateTime.now().subtract(window);
    final groups = <String, List<CrisisSignal>>{};

    for (final s in signals) {
      if (s.isProcessed) continue;
      if (s.timestamp.isBefore(cutoff)) continue;
      final sector = s.sector;
      final type = s.crisisHint;
      if (sector == null || type == null) continue;
      final key = '${sector.toLowerCase()}|${type.name}';
      groups.putIfAbsent(key, () => []).add(s);
    }

    final clusters = <SignalCluster>[];
    for (final entry in groups.entries) {
      final parts = entry.key.split('|');
      final cluster = SignalCluster(
        sector: entry.value.first.sector ?? parts[0],
        crisisType: entry.value.first.crisisHint!,
        signals: entry.value,
      );
      if (cluster.weight >= minWeight) clusters.add(cluster);
    }

    clusters.sort((a, b) => b.weight.compareTo(a.weight));
    return clusters;
  }
}
