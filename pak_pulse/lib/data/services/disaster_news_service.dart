import 'package:dio/dio.dart';

import '../models/disaster_news.dart';

/// Pulls real, live disaster events from GDACS — the Global Disaster Alert
/// and Coordination System (a joint UN / European Commission service).
///
/// Free, no API key. Returns floods and other hazards, with Pakistan and
/// the surrounding region prioritised. Falls back to an empty list on error
/// so the UI degrades gracefully.
class DisasterNewsService {
  DisasterNewsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  final Dio _dio;

  static const _endpoint =
      'https://www.gdacs.org/gdacsapi/api/events/geteventlist/EVENTS4APP';

  // Pakistan + neighbours — used to flag regionally relevant events.
  static const _regionCountries = {
    'pakistan',
    'india',
    'afghanistan',
    'iran',
    'islamic republic of iran',
    'china',
  };

  Future<List<DisasterNews>> fetchEvents() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_endpoint);
      if (response.statusCode != 200 || response.data == null) return const [];

      final features = response.data!['features'] as List?;
      if (features == null) return const [];

      final events = <DisasterNews>[];
      for (final f in features) {
        final p = (f as Map)['properties'] as Map?;
        if (p == null) continue;

        final country = (p['country'] ?? '').toString();
        final countryLower = country.toLowerCase();
        final isPakistan = countryLower.contains('pakistan');
        final isRegional = isPakistan ||
            _regionCountries.any((c) => countryLower.contains(c));

        DateTime? parseDate(dynamic v) =>
            v is String ? DateTime.tryParse(v) : null;

        events.add(DisasterNews(
          eventType: (p['eventtype'] ?? '').toString(),
          title: (p['name'] ?? p['eventname'] ?? 'Disaster event').toString(),
          description: (p['htmldescription'] ?? '').toString(),
          country: country,
          alertLevel: (p['alertlevel'] ?? 'Green').toString(),
          isPakistan: isPakistan,
          isRegional: isRegional,
          fromDate: parseDate(p['fromdate']),
          toDate: parseDate(p['todate']),
        ));
      }
      return events;
    } catch (_) {
      return const [];
    }
  }

  /// Flood-focused feed: Pakistan floods first, then regional floods, then
  /// any Pakistan/regional hazard so the card is never empty during a demo.
  Future<List<DisasterNews>> fetchFloodWatch() async {
    final all = await fetchEvents();
    if (all.isEmpty) return const [];

    int rank(DisasterNews e) {
      if (e.isFlood && e.isPakistan) return 0;
      if (e.isFlood && e.isRegional) return 1;
      if (e.isFlood) return 2;
      if (e.isRegional) return 3;
      return 4;
    }

    int alertWeight(String level) {
      switch (level.toLowerCase()) {
        case 'red':
          return 0;
        case 'orange':
          return 1;
        default:
          return 2;
      }
    }

    final sorted = [...all]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return alertWeight(a.alertLevel).compareTo(alertWeight(b.alertLevel));
      });

    return sorted.take(6).toList();
  }
}
