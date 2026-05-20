import '../models/crisis.dart';
import '../models/agent_step.dart';
import '../../core/constants/crisis_types.dart';
import 'mock_actions.dart';

class MockCrises {
  MockCrises._();

  static final DateTime _base = DateTime(2026, 5, 17, 14, 0);
  static DateTime _ago(int minutes) => _base.subtract(Duration(minutes: minutes));

  // ── ACTIVE CRISIS 001 — G-10 Urban Flooding ─────────────────────────────────

  static final Crisis crisis001 = Crisis(
    id: 'crisis_001',
    type: CrisisType.flood,
    title: 'Urban Flooding — G-10 Markaz',
    sector: 'G-10 Markaz',
    lat: 33.6900,
    lng: 73.0228,
    severity: SeverityLevel.critical,
    confidence: 0.91,
    riskScore: 87,
    detectedAt: _ago(40),
    affectedRadiusMeters: 800,
    summaryEn:
        'Severe flash flooding in G-10 Markaz caused by 47mm/hr rainfall. Multiple vehicles stranded, road network submerged. Rescue 1122 deployed. Immediate evacuation of G-10/2 and G-10/3 sub-sectors advised.',
    summaryUr:
        'جی-10 مارکیٹ میں شدید سیلاب کی صورتحال ہے۔ 47 ملی میٹر فی گھنٹہ بارش کی وجہ سے متعدد گاڑیاں پھنسی ہوئی ہیں۔ ریسکیو 1122 موقع پر موجود ہے۔ علاقہ مکینوں کو فوری طور پر محفوظ مقام پر منتقل ہونے کی ہدایت ہے۔',
    signalCount: 10,
    signalIds: ['sig_f01','sig_f02','sig_f03','sig_f04','sig_f05',
                 'sig_f06','sig_f07','sig_f08','sig_f09','sig_f10'],
    actions: MockActions.floodActions,
    reasoning: [
      AgentStep(
        id: 'step_001_signal',
        agentName: AgentName.signal,
        timestamp: _ago(39),
        inputSummary: 'Raw signal: "G-10 mein pani bhar gaya, gaariyan phans gayi hain, madad chahiye"',
        outputSummary: 'Language: Roman Urdu | Sector: G-10 Markaz | Crisis: flood | Severity: critical | Confidence: 0.93',
        reasoning:
            'Detected Roman Urdu keywords: "pani" (water), "gaariyan phans" (vehicles stuck), "madad chahiye" (need help). Sector resolved to G-10 Markaz via IslamabadSectors lookup. Multiple concurrent signals from same sector confirm flood event.',
        toolsUsed: ['normalize_text', 'geocode_sector'],
        durationMs: 342,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_001_detection',
        agentName: AgentName.detection,
        timestamp: _ago(38),
        inputSummary: '10 signals from G-10 in last 40 minutes including 1 PMD official alert',
        outputSummary: 'NEW CRISIS confirmed | Type: flood | Cluster: crisis_001 | Signals: 10 | Confidence: 0.91',
        reasoning:
            'Cluster threshold met: 10 signals from G-10/G-11 sector within 40 minutes (threshold: 3+). PMD official alert (3x weight) providing authoritative corroboration. NDMA advisory further confirms. Crisis classification: urban_flood. New crisis object created.',
        toolsUsed: ['get_recent_signals', 'get_active_crises'],
        durationMs: 518,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_001_severity',
        agentName: AgentName.severity,
        timestamp: _ago(37),
        inputSummary: 'Crisis: G-10 flood | 10 signals (1 PMD 3x, 1 NDMA 3x, 8 citizen 1x) | Sector population: 45,000',
        outputSummary: 'Severity: CRITICAL | RSI: 87 | Affected radius: 800m | Casualty risk: HIGH',
        reasoning:
            'RSI calculation: Base signal score 48 (10 signals). PMD official source multiplier: +18. NDMA advisory: +12. Historical context: G-10 floods annually in monsoon, 2022 event caused 3 casualties. Population density G-10: 45,000 residents. Infrastructure: underground drainage overflow confirmed. Total RSI: 87. Urdu summary generated.',
        toolsUsed: ['get_weather_overlay', 'get_population_density', 'count_signals_by_source'],
        durationMs: 724,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_001_action',
        agentName: AgentName.action,
        timestamp: _ago(36),
        inputSummary: 'CRITICAL flood in G-10. RSI 87. 45,000 affected. Vehicles stranded. Road blocked.',
        outputSummary: '3 actions generated: Rescue 1122 dispatch (P1) | Traffic reroute via Service Road Eastern | Bilingual SMS to 45,000',
        reasoning:
            'Priority 1: Life safety — Rescue 1122 dispatch is non-negotiable given vehicle entrapments and rising water. Priority 2: Traffic management — Service Road Eastern is the only viable alternate given G-10 underpasses flooded. Priority 3: Mass communication — 45,000 residents need immediate warning. Agencies selected based on jurisdiction: Rescue 1122 (life threats), ITP (traffic), NDMA (mass alerts).',
        toolsUsed: ['create_rescue_ticket', 'compute_reroute', 'draft_sms_alert'],
        durationMs: 891,
        isCompleted: true,
        usedMockFallback: true,
      ),
    ],
    isActive: true,
  );

  // ── ACTIVE CRISIS 002 — Jacobabad Heatwave ──────────────────────────────────

  static final Crisis crisis002 = Crisis(
    id: 'crisis_002',
    type: CrisisType.heatwave,
    title: 'Extreme Heatwave — Jacobabad Region',
    sector: 'Jacobabad District',
    lat: 28.2769,
    lng: 68.4511,
    severity: SeverityLevel.high,
    confidence: 0.94,
    riskScore: 79,
    detectedAt: _ago(70),
    affectedRadiusMeters: 15000,
    summaryEn:
        'Record-breaking temperature of 51.2°C recorded in Jacobabad, Sindh. 15 heatstroke patients admitted to district hospital. Power outages compounding danger. NDMA activating 5 cooling centers. Vulnerable populations — elderly, children, livestock — at extreme risk.',
    summaryUr:
        'جیکب آباد میں درجہ حرارت 51 ڈگری سینٹی گریڈ تک پہنچ گیا جو اس سال کا سب سے زیادہ ہے۔ 15 افراد لو لگنے سے ہسپتال داخل ہیں۔ بجلی بندش صورتحال کو مزید خراب کر رہی ہے۔ این ڈی ایم اے کولنگ سینٹرز کھول رہا ہے۔',
    signalCount: 10,
    signalIds: ['sig_h01','sig_h02','sig_h03','sig_h04','sig_h05',
                 'sig_h06','sig_h07','sig_h08','sig_h09','sig_h10'],
    actions: MockActions.heatwaveActions,
    reasoning: [
      AgentStep(
        id: 'step_002_signal',
        agentName: AgentName.signal,
        timestamp: _ago(69),
        inputSummary: 'Raw signal: "Jacobabad mein garmi 51 degree ho gayi, AC bhi kaam nahi kar raha"',
        outputSummary: 'Language: Roman Urdu | Location: Jacobabad | Crisis: heatwave | Severity: critical | Confidence: 0.96',
        reasoning:
            'Roman Urdu keyword detection: "garmi" (heat), "degree" (temperature), "kaam nahi" (not working). Temperature 51°C confirmed against Pakistan historical records — Jacobabad regularly exceeds 50°C in May-June. PMD official reading corroborates citizen reports.',
        toolsUsed: ['normalize_text', 'geocode_sector'],
        durationMs: 287,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_002_detection',
        agentName: AgentName.detection,
        timestamp: _ago(68),
        inputSummary: '10 signals from Jacobabad in last 70 minutes including PMD and NDMA official alerts',
        outputSummary: 'NEW CRISIS confirmed | Type: heatwave | Cluster: crisis_002 | Signals: 10 | Confidence: 0.94',
        reasoning:
            'PMD official temperature reading (3x weight) + NDMA advisory (3x weight) together provide authoritative confirmation. 8 citizen/twitter signals provide ground-truth corroboration. Temperature 51.2°C exceeds the WHO extreme heat threshold of 40°C by 11 degrees. Cluster confirmed.',
        toolsUsed: ['get_recent_signals', 'get_active_crises'],
        durationMs: 445,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_002_severity',
        agentName: AgentName.severity,
        timestamp: _ago(67),
        inputSummary: 'Crisis: Jacobabad heatwave | Temp: 51.2°C | 15 hospital admissions | Power outage | 10 signals',
        outputSummary: 'Severity: HIGH | RSI: 79 | Affected radius: 15km | Casualty risk: HIGH',
        reasoning:
            'RSI base: 42 (10 signals). PMD 3x multiplier: +15. NDMA 3x multiplier: +10. Hospital admissions factor: +8. Historical context: 2015 Karachi heatwave killed 1,200 in 3 days at similar temperatures. Power outage removing cooling capacity escalates risk. Population: 300,000 in district. RSI: 79. Slightly below critical (80) due to prior NDMA activation.',
        toolsUsed: ['get_weather_overlay', 'get_population_density', 'count_signals_by_source'],
        durationMs: 611,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_002_action',
        agentName: AgentName.action,
        timestamp: _ago(66),
        inputSummary: 'HIGH heatwave in Jacobabad. RSI 79. 15 hospital admissions. Power out. 300,000 population.',
        outputSummary: '3 actions: NDMA cooling centers (P1) | PDMA mobile medical units (P2) | PMD heat advisory broadcast (P3)',
        reasoning:
            'Priority 1: Cooling centers — immediate life-safety intervention for 300,000 population in 51°C with power outage. Priority 2: Medical deployment — 15 admissions signals need for IV fluids and on-site care. Priority 3: Mass communication — broadcast advisory prevents further outdoor exposure. Agency selection: NDMA (infrastructure), PDMA Sindh (medical), PMD (official advisory authority).',
        toolsUsed: ['create_rescue_ticket', 'draft_sms_alert'],
        durationMs: 756,
        isCompleted: true,
        usedMockFallback: true,
      ),
    ],
    isActive: true,
  );

  // ── ACTIVE CRISIS 003 — Faizabad Road Blockage ──────────────────────────────

  static final Crisis crisis003 = Crisis(
    id: 'crisis_003',
    type: CrisisType.protest,
    title: 'Road Blockage — Faizabad Interchange',
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    severity: SeverityLevel.high,
    confidence: 0.88,
    riskScore: 72,
    detectedAt: _ago(45),
    affectedRadiusMeters: 3000,
    summaryEn:
        'Large-scale sit-in protest at Faizabad Interchange blocking all traffic between Rawalpindi and Islamabad. Estimated 50,000 protesters. Ambulances unable to pass. ITP deploying 40 officers. 9th Avenue recommended as alternate route.',
    summaryUr:
        'فیض آباد انٹرچینج پر بڑے پیمانے پر دھرنا جاری ہے جس سے راولپنڈی اور اسلام آباد کے درمیان تمام ٹریفک بند ہے۔ تقریباً 50 ہزار مظاہرین موجود ہیں۔ ایمبولینسیں بھی نہیں گزر پا رہیں۔ نویں ایونیو متبادل راستے کے طور پر استعمال کریں۔',
    signalCount: 10,
    signalIds: ['sig_p01','sig_p02','sig_p03','sig_p04','sig_p05',
                 'sig_p06','sig_p07','sig_p08','sig_p09','sig_p10'],
    actions: MockActions.protestActions,
    reasoning: [
      AgentStep(
        id: 'step_003_signal',
        agentName: AgentName.signal,
        timestamp: _ago(44),
        inputSummary: 'Raw signal: "Faizabad completely blocked. Been stuck for 2 hours. Ambulance behind me cannot get through."',
        outputSummary: 'Language: English | Sector: Faizabad Interchange | Crisis: protest | Severity: high | Confidence: 0.91',
        reasoning:
            'English signal with high specificity: location named (Faizabad), duration given (2 hours), critical detail (ambulance blocked). Faizabad Interchange is a historically recurring protest location — mapped in IslamabadSectors constants. ITP traffic advisory provides official confirmation.',
        toolsUsed: ['normalize_text', 'geocode_sector'],
        durationMs: 312,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_003_detection',
        agentName: AgentName.detection,
        timestamp: _ago(43),
        inputSummary: '10 signals from Faizabad area in last 45 minutes including ITP official advisory',
        outputSummary: 'NEW CRISIS confirmed | Type: protest | Cluster: crisis_003 | Signals: 10 | Confidence: 0.88',
        reasoning:
            'ITP official advisory (3x weight) + 9 citizen/twitter signals. All signals converge on Faizabad Interchange. Crisis type: road_blockage/protest. Historical pattern: Faizabad sit-ins typically last 1-3 days — duration estimate informs action planning. Emergency vehicle obstruction elevates priority.',
        toolsUsed: ['get_recent_signals', 'get_active_crises'],
        durationMs: 389,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_003_severity',
        agentName: AgentName.severity,
        timestamp: _ago(42),
        inputSummary: 'Protest crisis at Faizabad. 50,000 protesters. Ambulances blocked. 10 signals. ITP deployed.',
        outputSummary: 'Severity: HIGH | RSI: 72 | Affected radius: 3km | Casualty risk: MODERATE',
        reasoning:
            'RSI base: 38 (10 signals). ITP official 3x: +12. Ambulance obstruction factor (life risk): +15. Crowd size estimate 50,000 (large, difficult to disperse): +7. Historical Faizabad duration (1-3 days): sustained disruption. Affected routes: Murree Road, IJP Road, Srinagar Highway — major arteries. RSI: 72. HIGH severity. Not critical since no direct weather/flooding life threat.',
        toolsUsed: ['get_weather_overlay', 'get_population_density', 'count_signals_by_source'],
        durationMs: 534,
        isCompleted: true,
        usedMockFallback: true,
      ),
      AgentStep(
        id: 'step_003_action',
        agentName: AgentName.action,
        timestamp: _ago(41),
        inputSummary: 'HIGH blockage at Faizabad. RSI 72. Ambulances blocked. 120,000 commuters affected.',
        outputSummary: '3 actions: ITP deployment 40 officers (P1) | Reroute via 9th Avenue (P2) | Public alert SMS 120,000 (P3)',
        reasoning:
            'Priority 1: Emergency corridor — ambulance blockage is the most critical issue. 40 ITP officers needed to physically create emergency lane through crowd. Priority 2: Traffic reroute — 9th Avenue is the only viable alternate for Rawalpindi-Islamabad traffic. Priority 3: Public alert — 120,000 daily commuters need advance warning to avoid the corridor.',
        toolsUsed: ['create_rescue_ticket', 'compute_reroute', 'draft_sms_alert'],
        durationMs: 682,
        isCompleted: true,
        usedMockFallback: true,
      ),
    ],
    isActive: true,
  );

  // ── HISTORICAL CRISES (5) ────────────────────────────────────────────────────

  static final Crisis hist001 = Crisis(
    id: 'hist_001',
    type: CrisisType.flood,
    title: 'Monsoon Flood — I-8 Sector',
    sector: 'I-8',
    lat: 33.6722,
    lng: 73.0631,
    severity: SeverityLevel.high,
    confidence: 0.88,
    riskScore: 71,
    detectedAt: DateTime(2026, 5, 10, 11, 30),
    affectedRadiusMeters: 600,
    summaryEn: 'I-8 sector flooded after 38mm rainfall. 6 vehicles stranded. Drained within 4 hours.',
    summaryUr: 'آئی-8 سیکٹر میں سیلاب آیا، 6 گاڑیاں پھنسیں، 4 گھنٹے میں صورتحال کنٹرول ہو گئی۔',
    signalCount: 7,
    signalIds: [],
    actions: [],
    reasoning: [],
    isActive: false,
  );

  static final Crisis hist002 = Crisis(
    id: 'hist_002',
    type: CrisisType.protest,
    title: 'Road Blockage — Blue Area',
    sector: 'Blue Area',
    lat: 33.7215,
    lng: 73.0644,
    severity: SeverityLevel.moderate,
    confidence: 0.81,
    riskScore: 52,
    detectedAt: DateTime(2026, 5, 12, 15, 0),
    affectedRadiusMeters: 1500,
    summaryEn: 'Small protest at Blue Area disrupted Constitution Avenue traffic for 3 hours. Resolved peacefully.',
    summaryUr: 'بلیو ایریا میں چھوٹا احتجاج، 3 گھنٹے ٹریفک متاثر، پرامن طور پر ختم ہوا۔',
    signalCount: 5,
    signalIds: [],
    actions: [],
    reasoning: [],
    isActive: false,
  );

  static final Crisis hist003 = Crisis(
    id: 'hist_003',
    type: CrisisType.heatwave,
    title: 'Heatwave Alert — Islamabad',
    sector: 'Islamabad Wide',
    lat: 33.7215,
    lng: 73.0644,
    severity: SeverityLevel.moderate,
    confidence: 0.76,
    riskScore: 58,
    detectedAt: DateTime(2026, 5, 5, 13, 0),
    affectedRadiusMeters: 20000,
    summaryEn: 'Islamabad recorded 44°C. Heat advisory issued. No casualties. Cooling centers at D-Ground activated.',
    summaryUr: 'اسلام آباد میں 44 ڈگری درجہ حرارت، ہیٹ ایڈوائزری جاری، ڈی گراؤنڈ کولنگ سینٹر فعال کیا گیا۔',
    signalCount: 8,
    signalIds: [],
    actions: [],
    reasoning: [],
    isActive: false,
  );

  static final Crisis hist004 = Crisis(
    id: 'hist_004',
    type: CrisisType.flood,
    title: 'Flash Flood — G-11 Sector',
    sector: 'G-11',
    lat: 33.6850,
    lng: 72.9980,
    severity: SeverityLevel.critical,
    confidence: 0.93,
    riskScore: 82,
    detectedAt: DateTime(2026, 4, 28, 9, 15),
    affectedRadiusMeters: 700,
    summaryEn: 'G-11 flash flood. 2 families evacuated. 1 vehicle submerged. Rescue 1122 ticket R1122-IB-4102 resolved in 6 hours.',
    summaryUr: 'جی-11 میں اچانک سیلاب، 2 خاندان نکالے گئے، ریسکیو 1122 نے 6 گھنٹے میں صورتحال کنٹرول کی۔',
    signalCount: 12,
    signalIds: [],
    actions: [],
    reasoning: [],
    isActive: false,
  );

  static final Crisis hist005 = Crisis(
    id: 'hist_005',
    type: CrisisType.protest,
    title: 'Road Blockage — Committee Chowk',
    sector: 'Committee Chowk',
    lat: 33.5847,
    lng: 73.0479,
    severity: SeverityLevel.high,
    confidence: 0.85,
    riskScore: 65,
    detectedAt: DateTime(2026, 4, 20, 17, 30),
    affectedRadiusMeters: 2000,
    summaryEn: 'Committee Chowk protest blocked Rawalpindi-Islamabad routes for 6 hours. ITP ticket ITP-2198 cleared by midnight.',
    summaryUr: 'کمیٹی چوک احتجاج 6 گھنٹے جاری رہا، آدھی رات تک صورتحال معمول پر آئی۔',
    signalCount: 9,
    signalIds: [],
    actions: [],
    reasoning: [],
    isActive: false,
  );

  // Active crises start empty — the AI pipeline creates them when real signals
  // are processed. The 3 scenario crises below are kept as historical reference.
  static List<Crisis> get activeCrises => [];
  static List<Crisis> get historicalCrises => [
        crisis001,
        crisis002,
        crisis003,
        hist001,
        hist002,
        hist003,
        hist004,
        hist005,
      ];
  static List<Crisis> get allCrises => [...activeCrises, ...historicalCrises];
}
