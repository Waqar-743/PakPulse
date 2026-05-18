import '../../core/constants/crisis_types.dart';

class CrisisAction {
  final String id;
  final ActionType type;
  final ActionStatus status;
  final String title;
  final String description;
  final String targetAgency;
  final Map<String, dynamic> payload;
  final DateTime? executedAt;
  final String? mockTicketId;
  final String? mockResponse;

  const CrisisAction({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.targetAgency,
    required this.payload,
    this.executedAt,
    this.mockTicketId,
    this.mockResponse,
  });

  factory CrisisAction.fromJson(Map<String, dynamic> j) => CrisisAction(
        id: j['id'] as String,
        type: ActionType.values.byName(j['type'] as String),
        status: ActionStatus.values.byName(j['status'] as String),
        title: j['title'] as String,
        description: j['description'] as String,
        targetAgency: j['targetAgency'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        executedAt: j['executedAt'] == null
            ? null
            : DateTime.parse(j['executedAt'] as String),
        mockTicketId: j['mockTicketId'] as String?,
        mockResponse: j['mockResponse'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': status.name,
        'title': title,
        'description': description,
        'targetAgency': targetAgency,
        'payload': payload,
        'executedAt': executedAt?.toIso8601String(),
        'mockTicketId': mockTicketId,
        'mockResponse': mockResponse,
      };

  CrisisAction copyWith({
    String? id,
    ActionType? type,
    ActionStatus? status,
    String? title,
    String? description,
    String? targetAgency,
    Map<String, dynamic>? payload,
    DateTime? executedAt,
    String? mockTicketId,
    String? mockResponse,
  }) =>
      CrisisAction(
        id: id ?? this.id,
        type: type ?? this.type,
        status: status ?? this.status,
        title: title ?? this.title,
        description: description ?? this.description,
        targetAgency: targetAgency ?? this.targetAgency,
        payload: payload ?? this.payload,
        executedAt: executedAt ?? this.executedAt,
        mockTicketId: mockTicketId ?? this.mockTicketId,
        mockResponse: mockResponse ?? this.mockResponse,
      );
}
