import '../../core/constants/crisis_types.dart';
import 'agent_step.dart';
import 'crisis_action.dart';

class Crisis {
  final String id;
  final CrisisType type;
  final String title;
  final String sector;
  final double lat;
  final double lng;
  final SeverityLevel severity;
  final double confidence;
  final int riskScore;
  final DateTime detectedAt;
  final int affectedRadiusMeters;
  final String summaryEn;
  final String summaryUr;
  final int signalCount;
  final List<String> signalIds;
  final List<CrisisAction> actions;
  final List<AgentStep> reasoning;
  final bool isActive;

  const Crisis({
    required this.id,
    required this.type,
    required this.title,
    required this.sector,
    required this.lat,
    required this.lng,
    required this.severity,
    required this.confidence,
    required this.riskScore,
    required this.detectedAt,
    required this.affectedRadiusMeters,
    required this.summaryEn,
    required this.summaryUr,
    required this.signalCount,
    required this.signalIds,
    required this.actions,
    required this.reasoning,
    this.isActive = true,
  });

  factory Crisis.fromJson(Map<String, dynamic> j) => Crisis(
        id: j['id'] as String,
        type: CrisisType.values.byName(j['type'] as String),
        title: j['title'] as String,
        sector: j['sector'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        severity: SeverityLevel.values.byName(j['severity'] as String),
        confidence: (j['confidence'] as num).toDouble(),
        riskScore: j['riskScore'] as int,
        detectedAt: DateTime.parse(j['detectedAt'] as String),
        affectedRadiusMeters: j['affectedRadiusMeters'] as int,
        summaryEn: j['summaryEn'] as String,
        summaryUr: j['summaryUr'] as String,
        signalCount: j['signalCount'] as int,
        signalIds: List<String>.from(j['signalIds'] as List),
        actions: (j['actions'] as List)
            .map((e) => CrisisAction.fromJson(e as Map<String, dynamic>))
            .toList(),
        reasoning: (j['reasoning'] as List)
            .map((e) => AgentStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'sector': sector,
        'lat': lat,
        'lng': lng,
        'severity': severity.name,
        'confidence': confidence,
        'riskScore': riskScore,
        'detectedAt': detectedAt.toIso8601String(),
        'affectedRadiusMeters': affectedRadiusMeters,
        'summaryEn': summaryEn,
        'summaryUr': summaryUr,
        'signalCount': signalCount,
        'signalIds': signalIds,
        'actions': actions.map((a) => a.toJson()).toList(),
        'reasoning': reasoning.map((r) => r.toJson()).toList(),
        'isActive': isActive,
      };

  Crisis copyWith({
    String? id,
    CrisisType? type,
    String? title,
    String? sector,
    double? lat,
    double? lng,
    SeverityLevel? severity,
    double? confidence,
    int? riskScore,
    DateTime? detectedAt,
    int? affectedRadiusMeters,
    String? summaryEn,
    String? summaryUr,
    int? signalCount,
    List<String>? signalIds,
    List<CrisisAction>? actions,
    List<AgentStep>? reasoning,
    bool? isActive,
  }) =>
      Crisis(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        sector: sector ?? this.sector,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        severity: severity ?? this.severity,
        confidence: confidence ?? this.confidence,
        riskScore: riskScore ?? this.riskScore,
        detectedAt: detectedAt ?? this.detectedAt,
        affectedRadiusMeters: affectedRadiusMeters ?? this.affectedRadiusMeters,
        summaryEn: summaryEn ?? this.summaryEn,
        summaryUr: summaryUr ?? this.summaryUr,
        signalCount: signalCount ?? this.signalCount,
        signalIds: signalIds ?? this.signalIds,
        actions: actions ?? this.actions,
        reasoning: reasoning ?? this.reasoning,
        isActive: isActive ?? this.isActive,
      );
}
