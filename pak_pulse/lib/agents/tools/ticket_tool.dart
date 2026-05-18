import 'dart:math';

class TicketRecord {
  final String ticketId;
  final String agency;
  final String sector;
  final String crisisType;
  final DateTime createdAt;
  final Map<String, dynamic> response;

  const TicketRecord({
    required this.ticketId,
    required this.agency,
    required this.sector,
    required this.crisisType,
    required this.createdAt,
    required this.response,
  });
}

class TicketTool {
  TicketTool._();

  static final List<TicketRecord> _log = [];
  static final Random _rng = Random();

  static List<TicketRecord> get executionLog => List.unmodifiable(_log);

  static Map<String, dynamic> createRescueTicket({
    required String sector,
    required String crisisType,
    int units = 2,
  }) {
    final id = 'R1122-IB-${_padded(_rng.nextInt(9999))}';
    final response = {
      'ticket_id': id,
      'agency': 'Rescue 1122 Islamabad',
      'status': 'DISPATCHED',
      'units_dispatched': units,
      'personnel_count': units * 4,
      'eta_minutes': 8 + _rng.nextInt(8),
      'destination_sector': sector,
      'crisis_type': crisisType,
      'priority': 'P1_LIFE_SAFETY',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _log.add(TicketRecord(
      ticketId: id,
      agency: 'Rescue 1122',
      sector: sector,
      crisisType: crisisType,
      createdAt: DateTime.now(),
      response: response,
    ));
    return response;
  }

  static Map<String, dynamic> createItpTicket({
    required String sector,
    required String alternateRoute,
  }) {
    final id = 'ITP-${_padded(_rng.nextInt(9999))}';
    final response = {
      'ticket_id': id,
      'agency': 'Islamabad Traffic Police',
      'status': 'OFFICERS_DISPATCHED',
      'officers_assigned': 4 + _rng.nextInt(6),
      'blocked_sector': sector,
      'alternate_route': alternateRoute,
      'eta_minutes': 5 + _rng.nextInt(10),
      'timestamp': DateTime.now().toIso8601String(),
    };
    _log.add(TicketRecord(
      ticketId: id,
      agency: 'ITP',
      sector: sector,
      crisisType: 'protest',
      createdAt: DateTime.now(),
      response: response,
    ));
    return response;
  }

  static Map<String, dynamic> createNdmaTicket({
    required String sector,
    required String crisisType,
  }) {
    final id = 'NDMA-${crisisType.substring(0, 2).toUpperCase()}-${_padded(_rng.nextInt(9999))}';
    final response = {
      'ticket_id': id,
      'agency': 'NDMA Emergency Operations',
      'status': 'ADVISORY_BROADCAST',
      'broadcast_channels': ['SMS', 'TV_TICKER', 'RADIO'],
      'sector': sector,
      'crisis_type': crisisType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _log.add(TicketRecord(
      ticketId: id,
      agency: 'NDMA',
      sector: sector,
      crisisType: crisisType,
      createdAt: DateTime.now(),
      response: response,
    ));
    return response;
  }

  static void clearLog() => _log.clear();

  static String _padded(int n) => n.toString().padLeft(4, '0');
}
