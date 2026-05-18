import '../models/crisis_signal.dart';
import '../../core/constants/crisis_types.dart';

class MockSignals {
  MockSignals._();

  static final DateTime _base = DateTime(2026, 5, 17, 14, 0);
  static DateTime _ago(int minutes) => _base.subtract(Duration(minutes: minutes));

  // ── FLOOD SIGNALS (10) ──────────────────────────────────────────────────────

  static final CrisisSignal f01 = CrisisSignal(
    id: 'sig_f01',
    source: SignalSource.twitter,
    rawText: 'G-10 mein pani bhar gaya, gaariyan phans gayi hain, madad chahiye',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(5),
    sector: 'G-10',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal f02 = CrisisSignal(
    id: 'sig_f02',
    source: SignalSource.twitter,
    rawText: 'G-10 underpass completely flooded. 3 vehicles stuck near main chowk. Police please help.',
    language: SignalLanguage.english,
    timestamp: _ago(8),
    sector: 'G-10',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal f03 = CrisisSignal(
    id: 'sig_f03',
    source: SignalSource.citizen,
    rawText: 'جی دس مارکیٹ کے قریب سڑک پر پانی کھڑا ہے',
    language: SignalLanguage.urdu,
    timestamp: _ago(12),
    sector: 'G-10 Markaz',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal f04 = CrisisSignal(
    id: 'sig_f04',
    source: SignalSource.pmd,
    rawText: 'PMD ALERT: Rainfall intensity 47mm/hr recorded Islamabad Zone 3. Flash flood warning issued for G-10, G-11 sectors.',
    language: SignalLanguage.english,
    timestamp: _ago(15),
    sector: 'G-10',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal f05 = CrisisSignal(
    id: 'sig_f05',
    source: SignalSource.traffic,
    rawText: 'Srinagar Highway blocked near Faizabad junction due to flash flooding. Avoid route.',
    language: SignalLanguage.english,
    timestamp: _ago(18),
    sector: 'Faizabad',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal f06 = CrisisSignal(
    id: 'sig_f06',
    source: SignalSource.twitter,
    rawText: 'G-11 mein bhi pani aa gaya, nali overflow ho gayi, ghar mein dakhil ho raha hai pani',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(22),
    sector: 'G-11',
    lat: 33.6850,
    lng: 72.9980,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal f07 = CrisisSignal(
    id: 'sig_f07',
    source: SignalSource.citizen,
    rawText: 'گیارہ میں بھی سیلاب آ گیا ہے، بچوں کو نکالنا پڑ رہا ہے',
    language: SignalLanguage.urdu,
    timestamp: _ago(25),
    sector: 'G-11',
    lat: 33.6850,
    lng: 72.9980,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal f08 = CrisisSignal(
    id: 'sig_f08',
    source: SignalSource.twitter,
    rawText: 'G-10 Markaz service road pani mein doob gaya, koi aane jaane wala nahi, rescue team bulao',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(30),
    sector: 'G-10 Markaz',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal f09 = CrisisSignal(
    id: 'sig_f09',
    source: SignalSource.ndma,
    rawText: 'NDMA FLASH FLOOD ADVISORY: G-10, G-11 Islamabad. Citizens advised to avoid low-lying areas. Rescue 1122 units deployed.',
    language: SignalLanguage.english,
    timestamp: _ago(35),
    sector: 'G-10',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal f10 = CrisisSignal(
    id: 'sig_f10',
    source: SignalSource.twitter,
    rawText: 'Water level rising fast in G-10/2. My car is submerged up to the windows. Need immediate help at Main Market road.',
    language: SignalLanguage.english,
    timestamp: _ago(40),
    sector: 'G-10',
    lat: 33.6900,
    lng: 73.0228,
    crisisHint: CrisisType.flood,
    severityHint: SeverityLevel.critical,
  );

  // ── HEATWAVE SIGNALS (10) ───────────────────────────────────────────────────

  static final CrisisSignal h01 = CrisisSignal(
    id: 'sig_h01',
    source: SignalSource.twitter,
    rawText: 'Jacobabad mein garmi 51 degree ho gayi, AC bhi kaam nahi kar raha, log bahar nahi ja saktey',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(10),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal h02 = CrisisSignal(
    id: 'sig_h02',
    source: SignalSource.pmd,
    rawText: 'PMD WARNING: Temperature in Jacobabad has reached 51.2°C — highest recorded this year. Extreme heat emergency declared.',
    language: SignalLanguage.english,
    timestamp: _ago(20),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal h03 = CrisisSignal(
    id: 'sig_h03',
    source: SignalSource.citizen,
    rawText: 'جیکب آباد میں گرمی کی وجہ سے دو افراد بے ہوش ہو گئے، ہسپتال بھر گئے ہیں',
    language: SignalLanguage.urdu,
    timestamp: _ago(25),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal h04 = CrisisSignal(
    id: 'sig_h04',
    source: SignalSource.ndma,
    rawText: 'NDMA HEAT EMERGENCY: Jacobabad and Sukkur district temperatures exceed 50°C. Cooling centers activated. Avoid outdoor activity 11am–5pm.',
    language: SignalLanguage.english,
    timestamp: _ago(30),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal h05 = CrisisSignal(
    id: 'sig_h05',
    source: SignalSource.twitter,
    rawText: 'Bijli 8 ghante gaye, inverter bhi band, 3 bache ghar mein hain, garmi 50 se upar hai, koi madad karo',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(35),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal h06 = CrisisSignal(
    id: 'sig_h06',
    source: SignalSource.citizen,
    rawText: 'گرمی سے بچنے کے لیے لوگ باہر سو رہے ہیں لیکن لوڈشیڈنگ سے پنکھا بھی نہیں چلتا',
    language: SignalLanguage.urdu,
    timestamp: _ago(42),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal h07 = CrisisSignal(
    id: 'sig_h07',
    source: SignalSource.twitter,
    rawText: 'Hospital in Jacobabad overwhelmed. 15 heatstroke patients admitted in last 3 hours. Blood pressure dropping in elderly.',
    language: SignalLanguage.english,
    timestamp: _ago(48),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal h08 = CrisisSignal(
    id: 'sig_h08',
    source: SignalSource.twitter,
    rawText: 'Garmi itni shadeed hai ke roads pe tar pighal raha hai, cement block crack ho gaye hain Jacobabad mein',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(55),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal h09 = CrisisSignal(
    id: 'sig_h09',
    source: SignalSource.citizen,
    rawText: 'Livestock dying from heat. Cattle water supplies exhausted. Farmers in Jacobabad district need urgent assistance.',
    language: SignalLanguage.english,
    timestamp: _ago(62),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal h10 = CrisisSignal(
    id: 'sig_h10',
    source: SignalSource.twitter,
    rawText: 'No power, no water, 51 degrees outside. This is not survivable. Government must open cooling centers now in Jacobabad.',
    language: SignalLanguage.english,
    timestamp: _ago(70),
    sector: null,
    lat: 28.2769,
    lng: 68.4511,
    crisisHint: CrisisType.heatwave,
    severityHint: SeverityLevel.critical,
  );

  // ── PROTEST SIGNALS (10) ────────────────────────────────────────────────────

  static final CrisisSignal p01 = CrisisSignal(
    id: 'sig_p01',
    source: SignalSource.twitter,
    rawText: 'Faizabad completely blocked. Been stuck for 2 hours. Ambulance behind me cannot get through.',
    language: SignalLanguage.english,
    timestamp: _ago(6),
    sector: 'Faizabad',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p02 = CrisisSignal(
    id: 'sig_p02',
    source: SignalSource.citizen,
    rawText: 'فیض آباد انٹرچینج مکمل بند ہے، ہزاروں گاڑیاں پھنسی ہیں',
    language: SignalLanguage.urdu,
    timestamp: _ago(10),
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p03 = CrisisSignal(
    id: 'sig_p03',
    source: SignalSource.twitter,
    rawText: 'Faizabad interchange band ho gaya, dharna shuru ho gaya hai, Murree Road aur IJP Road dono block hain',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(14),
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p04 = CrisisSignal(
    id: 'sig_p04',
    source: SignalSource.traffic,
    rawText: 'ITP ADVISORY: Faizabad Interchange closed due to sit-in protest. Use 9th Avenue or IJP Road as alternate routes.',
    language: SignalLanguage.english,
    timestamp: _ago(18),
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p05 = CrisisSignal(
    id: 'sig_p05',
    source: SignalSource.citizen,
    rawText: 'راولپنڈی سے اسلام آباد آنا ناممکن ہو گیا ہے، فیض آباد پر ہزاروں لوگ جمع ہیں',
    language: SignalLanguage.urdu,
    timestamp: _ago(22),
    sector: 'Faizabad',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p06 = CrisisSignal(
    id: 'sig_p06',
    source: SignalSource.twitter,
    rawText: 'Committee Chowk bhi block ho gaya, Saddar se Islamabad ka rasta band, puri city jam ho gayi',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(26),
    sector: 'Committee Chowk',
    lat: 33.5847,
    lng: 73.0479,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p07 = CrisisSignal(
    id: 'sig_p07',
    source: SignalSource.twitter,
    rawText: 'Faizabad sit-in now estimated at 50,000+ people. Police deployed but crowd increasing. Expect 48-hour disruption minimum.',
    language: SignalLanguage.english,
    timestamp: _ago(30),
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal p08 = CrisisSignal(
    id: 'sig_p08',
    source: SignalSource.twitter,
    rawText: 'Pindi se Islamabad jane wali saari buses ruk gayi hain, log paidal ja rahe hain, koi rasta nahi',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(35),
    sector: 'Faizabad',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static final CrisisSignal p09 = CrisisSignal(
    id: 'sig_p09',
    source: SignalSource.citizen,
    rawText: 'Emergency vehicle stuck at Faizabad for 45 minutes. Patient inside needs urgent hospital care. This is life or death.',
    language: SignalLanguage.english,
    timestamp: _ago(40),
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.critical,
  );

  static final CrisisSignal p10 = CrisisSignal(
    id: 'sig_p10',
    source: SignalSource.twitter,
    rawText: 'Faizabad mein PTI ka dharna hai, police ki rang barsi, logo mein ghabrahat, halaat tense hain',
    language: SignalLanguage.romanUrdu,
    timestamp: _ago(45),
    sector: 'Faizabad Interchange',
    lat: 33.6938,
    lng: 73.0651,
    crisisHint: CrisisType.protest,
    severityHint: SeverityLevel.high,
  );

  static List<CrisisSignal> get floodSignals =>
      [f01, f02, f03, f04, f05, f06, f07, f08, f09, f10];

  static List<CrisisSignal> get heatwaveSignals =>
      [h01, h02, h03, h04, h05, h06, h07, h08, h09, h10];

  static List<CrisisSignal> get protestSignals =>
      [p01, p02, p03, p04, p05, p06, p07, p08, p09, p10];

  static List<CrisisSignal> get allSignals =>
      [...floodSignals, ...heatwaveSignals, ...protestSignals];
}
