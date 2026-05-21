/// A real road traffic incident from the TomTom Traffic Incidents API.
class RoadIncident {
  final int iconCategory;
  final int magnitudeOfDelay; // 0 unknown, 1 minor … 4 closure
  final String from;
  final String to;
  final double lengthMeters;
  final int? delaySeconds;
  final double? lat;
  final double? lng;
  final String description;

  const RoadIncident({
    required this.iconCategory,
    required this.magnitudeOfDelay,
    required this.from,
    required this.to,
    required this.lengthMeters,
    required this.description,
    this.delaySeconds,
    this.lat,
    this.lng,
  });

  /// TomTom iconCategory → human label.
  String get categoryLabel {
    switch (iconCategory) {
      case 1:
        return 'Accident';
      case 6:
        return 'Traffic Jam';
      case 7:
        return 'Lane Closed';
      case 8:
        return 'Road Closed';
      case 9:
        return 'Road Works';
      case 11:
        return 'Flooding';
      case 14:
        return 'Broken-down Vehicle';
      default:
        return description.isNotEmpty ? description : 'Incident';
    }
  }

  /// True when the incident actually blocks the road (closure or lane closure).
  bool get isBlockage => iconCategory == 7 || iconCategory == 8;

  /// True when the incident is severe enough to warrant a reroute.
  bool get isMajor => magnitudeOfDelay >= 3 || isBlockage;

  String get delayLabel {
    final d = delaySeconds;
    if (d == null || d <= 0) return '—';
    if (d < 60) return '${d}s';
    return '${(d / 60).round()} min';
  }
}
