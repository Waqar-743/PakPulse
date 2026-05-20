import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'data/models/crisis.dart';
import 'data/models/crisis_signal.dart';
import 'data/models/disaster_news.dart';
import 'data/models/live_conditions.dart';
import 'data/models/road_incident.dart';
import 'data/models/user_location.dart';
import 'data/mock/mock_crises.dart';
import 'data/mock/mock_signals.dart';
import 'data/mock/mock_agent_responses.dart';
import 'data/services/disaster_news_service.dart';
import 'data/services/live_conditions_service.dart';
import 'data/services/location_service.dart';
import 'data/services/traffic_service.dart';
import 'core/constants/crisis_types.dart';
import 'core/constants/pakistan_cities.dart';

const _uuid = Uuid();

// ── Crisis ───────────────────────────────────────────────────────────────────

class CrisisNotifier extends StateNotifier<List<Crisis>> {
  CrisisNotifier() : super(MockCrises.activeCrises);

  void addCrisis(Crisis crisis) => state = [...state, crisis];

  void updateCrisis(Crisis updated) {
    state = [
      for (final c in state)
        if (c.id == updated.id) updated else c,
    ];
  }

  void reset() => state = MockCrises.activeCrises;
}

final crisisListProvider =
    StateNotifierProvider<CrisisNotifier, List<Crisis>>((_) => CrisisNotifier());

// ── Signals ──────────────────────────────────────────────────────────────────

class SignalNotifier extends StateNotifier<List<CrisisSignal>> {
  SignalNotifier() : super(MockSignals.allSignals);

  void addSignal(CrisisSignal signal) => state = [signal, ...state];

  void reset() => state = MockSignals.allSignals;
}

final signalListProvider =
    StateNotifierProvider<SignalNotifier, List<CrisisSignal>>(
        (_) => SignalNotifier());

// ── Signal Simulator (stream — new signal every 8s) ──────────────────────────

final signalSimulatorProvider = StreamProvider<CrisisSignal>((ref) {
  final signals = MockSignals.allSignals;
  int index = 0;

  final controller = StreamController<CrisisSignal>();

  final timer = Timer.periodic(const Duration(seconds: 8), (_) {
    final base = signals[index % signals.length];
    final fresh = base.copyWith(
      id: 'live_${_uuid.v4().substring(0, 8)}',
      timestamp: DateTime.now(),
      isProcessed: false,
    );
    controller.add(fresh);
    ref.read(signalListProvider.notifier).addSignal(fresh);
    index++;
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// ── Mock Agent Responses ─────────────────────────────────────────────────────

final mockAgentResponsesProvider = Provider<MockAgentResponses>(
  (_) => const MockAgentResponses(),
);

// ── Persistent shell navigation ──────────────────────────────────────────────

/// The active tab index for the permanent bottom navigation shell.
/// 0 Home · 1 Signals · 2 Actions · 3 Settings.
final navIndexProvider = StateProvider<int>((_) => 0);

// ── User location (set once during onboarding) ───────────────────────────────

class UserLocationNotifier extends StateNotifier<UserLocation?> {
  UserLocationNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await LocationService.load();
  }

  /// Persists and broadcasts a new location (used by onboarding + settings).
  Future<void> setLocation(UserLocation location) async {
    await LocationService.save(location);
    state = location;
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocation?>(
        (_) => UserLocationNotifier());

/// Live weather for the user's stored city. Falls back to Islamabad if the
/// location has not loaded yet so the UI always has coordinates to query.
final userLiveConditionsProvider =
    FutureProvider.autoDispose<LiveConditions?>((ref) async {
  final loc = ref.watch(userLocationProvider);
  final svc = ref.watch(liveConditionsServiceProvider);
  return svc.fetchFor(
    latitude: loc?.lat ?? PakistanCities.fallback.lat,
    longitude: loc?.lng ?? PakistanCities.fallback.lng,
  );
});

// ── Settings ─────────────────────────────────────────────────────────────────

// Light mode is the only supported theme — the app launches and stays light.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.light);

// Defaults to whatever DEMO_MODE is set to in .env. When false, agents call
// the live LLM (Gemini) and fall back to mock only on error — "hybrid mode".
final demoModeProvider = StateProvider<bool>(
  (ref) => (dotenv.maybeGet('DEMO_MODE') ?? 'true').toLowerCase() == 'true',
);

final autoPlayProvider = StateProvider<bool>((ref) => false);

final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);

final appLocaleProvider = StateProvider<String>((ref) => 'en');

// ── Active crisis type color (for nav bar) ───────────────────────────────────

final activeCrisisColorProvider = Provider((ref) {
  final crises = ref.watch(crisisListProvider);
  if (crises.isEmpty) return null;
  // Return color of most urgent active crisis
  final sorted = [...crises]..sort((a, b) => a.severity.order.compareTo(b.severity.order));
  return sorted.first.type;
});

// ── Historical crises ─────────────────────────────────────────────────────────

final historicalCrisesProvider = Provider<List<Crisis>>(
  (_) => MockCrises.historicalCrises,
);

// ── Crisis by ID ─────────────────────────────────────────────────────────────

final crisisByIdProvider = Provider.family<Crisis?, String>((ref, id) {
  final all = [...ref.watch(crisisListProvider), ...MockCrises.historicalCrises];
  try {
    return all.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

// ── Filtered signals ─────────────────────────────────────────────────────────

final filteredSignalsProvider =
    Provider.family<List<CrisisSignal>, SignalFilter>((ref, filter) {
  final signals = ref.watch(signalListProvider);
  return signals.where((s) {
    if (filter.source != null && s.source != filter.source) return false;
    if (filter.language != null && s.language != filter.language) return false;
    if (filter.crisisType != null && s.crisisHint != filter.crisisType) {
      return false;
    }
    return true;
  }).toList();
});

class SignalFilter {
  final SignalSource? source;
  final SignalLanguage? language;
  final CrisisType? crisisType;

  const SignalFilter({this.source, this.language, this.crisisType});

  @override
  bool operator ==(Object other) =>
      other is SignalFilter &&
      other.source == source &&
      other.language == language &&
      other.crisisType == crisisType;

  @override
  int get hashCode => Object.hash(source, language, crisisType);
}

// ── Live conditions (Open-Meteo) ─────────────────────────────────────────────

final liveConditionsServiceProvider =
    Provider<LiveConditionsService>((_) => LiveConditionsService());

class LatLngKey {
  final double lat;
  final double lng;
  const LatLngKey(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      other is LatLngKey && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

final liveConditionsProvider =
    FutureProvider.family.autoDispose<LiveConditions?, LatLngKey>(
        (ref, key) async {
  final svc = ref.watch(liveConditionsServiceProvider);
  return svc.fetchFor(latitude: key.lat, longitude: key.lng);
});

// ── Disaster news feed (GDACS — live, no API key) ────────────────────────────

final disasterNewsServiceProvider =
    Provider<DisasterNewsService>((_) => DisasterNewsService());

/// Live flood-watch feed from GDACS — Pakistan and regional disasters.
final disasterFeedProvider =
    FutureProvider.autoDispose<List<DisasterNews>>((ref) async {
  final svc = ref.watch(disasterNewsServiceProvider);
  return svc.fetchFloodWatch();
});

// ── Live road incidents (TomTom Traffic) ─────────────────────────────────────

final trafficServiceProvider =
    Provider<TrafficService>((_) => TrafficService());

/// Real road incidents (closures, jams, accidents) around a given point.
final roadIncidentsProvider =
    FutureProvider.family.autoDispose<List<RoadIncident>, LatLngKey>(
        (ref, key) async {
  final svc = ref.watch(trafficServiceProvider);
  return svc.fetchIncidents(lat: key.lat, lng: key.lng);
});

