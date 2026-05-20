import '../models/crisis_action.dart';
import '../../core/constants/crisis_types.dart';

class MockActions {
  MockActions._();

  // ── G-10 FLOOD ACTIONS ──────────────────────────────────────────────────────

  static const CrisisAction floodTicket = CrisisAction(
    id: 'act_f01',
    type: ActionType.ticket,
    status: ActionStatus.pending,
    title: 'Dispatch Rescue 1122 — G-10 Flood',
    description:
        'Create emergency rescue ticket for G-10 Markaz flooding. Deploy 2 rescue boats and 8 personnel to G-10 Main Market road.',
    targetAgency: 'Rescue 1122 Islamabad',
    payload: {
      'sector': 'G-10 Markaz',
      'units_requested': 2,
      'personnel': 8,
      'crisis_type': 'urban_flood',
      'priority': 'P1',
    },
    mockTicketId: 'R1122-IB-4471',
    mockResponse:
        '{"status":"accepted","ticket":"R1122-IB-4471","eta_minutes":12,"units_dispatched":2,"personnel":8,"contact":"051-1122"}',
  );

  static const CrisisAction floodReroute = CrisisAction(
    id: 'act_f02',
    type: ActionType.reroute,
    status: ActionStatus.pending,
    title: 'Reroute Traffic — Service Road Eastern',
    description:
        'Block G-10 Main Market entry. Divert all inbound traffic via Service Road Eastern. Estimated 8-minute delay added to alternate route.',
    targetAgency: 'Islamabad Traffic Police (ITP)',
    payload: {
      'blocked_route': 'G-10 Main Bazaar Road',
      'alternate_route': 'Service Road Eastern',
      'direction': 'both',
    },
    mockTicketId: 'ITP-2231',
    mockResponse:
        '{"status":"reroute_activated","ticket":"ITP-2231","blocked":"G-10 Main Bazaar Road","alternate":"Service Road Eastern","time_added_minutes":8}',
  );

  static const CrisisAction floodAlert = CrisisAction(
    id: 'act_f03',
    type: ActionType.alert,
    status: ActionStatus.pending,
    title: 'Bilingual SMS Alert — G-10 Residents',
    description:
        'Send emergency SMS alert in English and Urdu to 45,000 registered mobile numbers in G-10/G-11 sectors warning of flash flooding.',
    targetAgency: 'NDMA Emergency Communication Cell',
    payload: {
      'sector': 'G-10',
      'recipient_count': 45000,
      'channels': ['sms', 'push'],
    },
    mockResponse:
        '{"status":"sent","recipients":45000,"message_en":"EMERGENCY: Flash flooding in G-10. Avoid area. Move to higher ground.","message_ur":"ہنگامی الرٹ: جی-10 میں اچانک سیلاب۔ علاقے سے گریز کریں اور بلند جگہ پر منتقل ہوں۔"}',
  );

  // ── JACOBABAD HEATWAVE ACTIONS ──────────────────────────────────────────────

  static const CrisisAction heatTicket = CrisisAction(
    id: 'act_h01',
    type: ActionType.ticket,
    status: ActionStatus.pending,
    title: 'Activate NDMA Cooling Centers — Jacobabad',
    description:
        'Emergency ticket to NDMA for immediate activation of 5 cooling centers across Jacobabad district. Provide chilled water, fans, and medical staff.',
    targetAgency: 'NDMA Sindh Provincial Office',
    payload: {
      'district': 'Jacobabad',
      'cooling_centers': 5,
      'medical_staff': 20,
      'crisis_type': 'extreme_heatwave',
    },
    mockTicketId: 'NDMA-HW-0220',
    mockResponse:
        '{"status":"accepted","ticket":"NDMA-HW-0220","centers_activated":5,"medical_staff_deployed":20,"eta_minutes":25}',
  );

  static const CrisisAction heatDispatch = CrisisAction(
    id: 'act_h02',
    type: ActionType.dispatch,
    status: ActionStatus.pending,
    title: 'Deploy Mobile Medical Units — Jacobabad',
    description:
        'Dispatch 3 PDMA mobile medical units with IV fluids and cooling equipment to Jacobabad city center and surrounding villages.',
    targetAgency: 'PDMA Sindh',
    payload: {
      'units': 3,
      'equipment': ['IV_fluids', 'cooling_vests', 'ORS'],
      'location': 'Jacobabad city center',
    },
    mockTicketId: 'PDMA-SD-0891',
    mockResponse:
        '{"status":"dispatched","ticket":"PDMA-SD-0891","units":3,"eta_minutes":35,"contact":"021-PDMA"}',
  );

  static const CrisisAction heatAlert = CrisisAction(
    id: 'act_h03',
    type: ActionType.alert,
    status: ActionStatus.pending,
    title: 'Heat Advisory Broadcast — Sindh Province',
    description:
        'Broadcast bilingual heat advisory across Sindh province via SMS and radio. Warn residents to stay indoors between 11am–5pm and visit cooling centers.',
    targetAgency: 'PMD Karachi',
    payload: {
      'region': 'Sindh Province',
      'channels': ['sms', 'radio', 'tv'],
      'recipient_count': 850000,
    },
    mockResponse:
        '{"status":"broadcast","recipients":850000,"message_en":"HEAT ADVISORY: Temperature 51C in Jacobabad. Stay indoors 11am-5pm. Visit cooling centers.","message_ur":"ہیٹ ایڈوائزری: جیکب آباد میں درجہ حرارت 51 ڈگری۔ صبح 11 سے شام 5 بجے تک گھر کے اندر رہیں۔"}',
  );

  // ── FAIZABAD PROTEST ACTIONS ────────────────────────────────────────────────

  static const CrisisAction protestTicket = CrisisAction(
    id: 'act_p01',
    type: ActionType.ticket,
    status: ActionStatus.pending,
    title: 'ITP Emergency Deployment — Faizabad',
    description:
        'Create ITP emergency ticket to deploy 40 traffic officers at Faizabad Interchange. Establish manual traffic control at Committee Chowk and 9th Avenue.',
    targetAgency: 'Islamabad Traffic Police (ITP)',
    payload: {
      'location': 'Faizabad Interchange',
      'officers': 40,
      'priority_lanes': ['ambulance', 'emergency'],
    },
    mockTicketId: 'ITP-2240',
    mockResponse:
        '{"status":"accepted","ticket":"ITP-2240","officers_deployed":40,"eta_minutes":8,"emergency_corridor":"activated"}',
  );

  static const CrisisAction protestReroute = CrisisAction(
    id: 'act_p02',
    type: ActionType.reroute,
    status: ActionStatus.pending,
    title: 'Reroute Traffic via 9th Avenue',
    description:
        'Close Faizabad Interchange to all non-emergency vehicles. Divert Rawalpindi–Islamabad traffic via 9th Avenue. Add 15 minutes to travel time.',
    targetAgency: 'Islamabad Traffic Police (ITP)',
    payload: {
      'blocked_route': 'Faizabad Interchange',
      'alternate_route': '9th Avenue',
      'time_added_minutes': 15,
    },
    mockTicketId: 'ITP-2241',
    mockResponse:
        '{"status":"reroute_activated","ticket":"ITP-2241","blocked":"Faizabad Interchange","alternate":"9th Avenue","polyline":"encoded_polyline_data","time_added_minutes":15}',
  );

  static const CrisisAction protestAlert = CrisisAction(
    id: 'act_p03',
    type: ActionType.alert,
    status: ActionStatus.pending,
    title: 'Public Road Closure Alert — Faizabad',
    description:
        'Send bilingual SMS alert to residents of G-7 through G-11 and Rawalpindi Saddar warning of Faizabad blockage and advising alternate routes.',
    targetAgency: 'NDMA Emergency Communication Cell',
    payload: {
      'sectors': ['G-7', 'G-8', 'G-9', 'G-10', 'G-11', 'Saddar Rawalpindi'],
      'recipient_count': 120000,
    },
    mockResponse:
        '{"status":"sent","recipients":120000,"message_en":"ROAD CLOSURE: Faizabad Interchange blocked. Use 9th Avenue alternate route.","message_ur":"سڑک بندش: فیض آباد انٹرچینج بند ہے۔ متبادل راستے کے طور پر نویں ایونیو استعمال کریں۔"}',
  );

  static List<CrisisAction> get floodActions =>
      [floodTicket, floodReroute, floodAlert];

  static List<CrisisAction> get heatwaveActions =>
      [heatTicket, heatDispatch, heatAlert];

  static List<CrisisAction> get protestActions =>
      [protestTicket, protestReroute, protestAlert];
}
