import '../../core/constants/crisis_types.dart';

class CrisisSignal {
  final String id;
  final SignalSource source;
  final String rawText;
  final SignalLanguage language;
  final DateTime timestamp;
  final String? sector;
  final double? lat;
  final double? lng;
  final CrisisType? crisisHint;
  final SeverityLevel? severityHint;
  final bool isProcessed;

  const CrisisSignal({
    required this.id,
    required this.source,
    required this.rawText,
    required this.language,
    required this.timestamp,
    this.sector,
    this.lat,
    this.lng,
    this.crisisHint,
    this.severityHint,
    this.isProcessed = false,
  });

  factory CrisisSignal.fromJson(Map<String, dynamic> j) => CrisisSignal(
        id: j['id'] as String,
        source: SignalSource.values.byName(j['source'] as String),
        rawText: j['rawText'] as String,
        language: SignalLanguage.values.byName(j['language'] as String),
        timestamp: DateTime.parse(j['timestamp'] as String),
        sector: j['sector'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        crisisHint: j['crisisHint'] == null
            ? null
            : CrisisType.values.byName(j['crisisHint'] as String),
        severityHint: j['severityHint'] == null
            ? null
            : SeverityLevel.values.byName(j['severityHint'] as String),
        isProcessed: j['isProcessed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'rawText': rawText,
        'language': language.name,
        'timestamp': timestamp.toIso8601String(),
        'sector': sector,
        'lat': lat,
        'lng': lng,
        'crisisHint': crisisHint?.name,
        'severityHint': severityHint?.name,
        'isProcessed': isProcessed,
      };

  CrisisSignal copyWith({
    String? id,
    SignalSource? source,
    String? rawText,
    SignalLanguage? language,
    DateTime? timestamp,
    String? sector,
    double? lat,
    double? lng,
    CrisisType? crisisHint,
    SeverityLevel? severityHint,
    bool? isProcessed,
  }) =>
      CrisisSignal(
        id: id ?? this.id,
        source: source ?? this.source,
        rawText: rawText ?? this.rawText,
        language: language ?? this.language,
        timestamp: timestamp ?? this.timestamp,
        sector: sector ?? this.sector,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        crisisHint: crisisHint ?? this.crisisHint,
        severityHint: severityHint ?? this.severityHint,
        isProcessed: isProcessed ?? this.isProcessed,
      );
}
