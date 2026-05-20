/// A real disaster event from the GDACS global feed (free, no API key).
class DisasterNews {
  final String eventType; // FL, EQ, WF, DR, TC
  final String title;
  final String description;
  final String country;
  final String alertLevel; // Green, Orange, Red
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isPakistan;
  final bool isRegional; // Pakistan or a neighbouring country

  const DisasterNews({
    required this.eventType,
    required this.title,
    required this.description,
    required this.country,
    required this.alertLevel,
    required this.isPakistan,
    required this.isRegional,
    this.fromDate,
    this.toDate,
  });

  bool get isFlood => eventType == 'FL';

  String get typeLabel {
    switch (eventType) {
      case 'FL':
        return 'Flood';
      case 'EQ':
        return 'Earthquake';
      case 'WF':
        return 'Wildfire';
      case 'DR':
        return 'Drought';
      case 'TC':
        return 'Cyclone';
      default:
        return 'Hazard';
    }
  }
}
