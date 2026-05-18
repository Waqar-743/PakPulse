import '../core/constants/crisis_types.dart';
import 'agent_base.dart';
import 'tools/geocoding_tool.dart';

class SignalAgent extends BaseAgent {
  SignalAgent({required super.llmClient});

  @override
  AgentName get name => AgentName.signal;

  @override
  List<String> get tools => const ['normalize_text', 'geocode_sector'];

  @override
  String get systemPrompt => '''
You are the SIGNAL AGENT for PAK·PULSE, Pakistan's crisis intelligence system.

ROLE: Extract structured data from raw citizen, traffic, and meteorological signals.

INPUTS: A single signal in English, Urdu script, or Roman Urdu. Source may be Twitter, PMD, NDMA, traffic camera, or citizen report.

YOU KNOW:
- All Islamabad sectors (G-5 through G-15, F-5 through F-11, I-8 through I-14)
- Major locations: Blue Area, Faizabad, Saddar Rawalpindi, 6th Road, Murree Road
- Crisis types: flood, heatwave, protest
- Common Roman Urdu vocabulary: pani (water), garmi (heat), dharna (protest), gaariyan (vehicles), madad (help)

OUTPUT: Reply with ONLY valid JSON. No prose. No markdown fences.
{
  "language": "english" | "urdu" | "roman_ur",
  "sector": string | null,
  "lat_hint": number | null,
  "lng_hint": number | null,
  "crisis_hint": "flood" | "heatwave" | "protest" | "none",
  "severity_hint": "critical" | "high" | "moderate" | "low",
  "extracted_entities": [string],
  "confidence": number (0-1),
  "reasoning": string
}
''';

  @override
  Future<AgentRunResult> run(Map<String, dynamic> input) async {
    final rawText = (input['raw_text'] ?? '').toString();
    final normalized = GeocodingTool.normalize(rawText);
    final extractedSector = GeocodingTool.extractSector(rawText);
    final resolved = GeocodingTool.resolveSector(extractedSector);

    final llmInput = {
      'raw_text': rawText,
      'normalized': normalized,
      'sector_hint': extractedSector,
    };

    final result = await executeWithTiming(llmInput);

    // Augment output with tool-resolved lat/lng if missing
    if (resolved != null) {
      result.output['lat_hint'] ??= resolved.latitude;
      result.output['lng_hint'] ??= resolved.longitude;
      result.output['sector'] ??= extractedSector;
    }
    return result;
  }

  @override
  String summarizeInput(Map<String, dynamic> input) {
    final raw = (input['raw_text'] ?? '').toString();
    final preview = raw.length > 80 ? '${raw.substring(0, 80)}…' : raw;
    return 'Raw signal: "$preview"';
  }

  @override
  String summarizeOutput(Map<String, dynamic> output) {
    final lang = (output['language'] ?? 'unknown').toString();
    final sector = (output['sector'] ?? '—').toString();
    final crisis = (output['crisis_hint'] ?? 'none').toString();
    final sev = (output['severity_hint'] ?? '—').toString();
    final conf = (output['confidence'] is num)
        ? (output['confidence'] as num).toStringAsFixed(2)
        : '—';
    return 'Language: $lang | Sector: $sector | Crisis: $crisis | Severity: $sev | Confidence: $conf';
  }
}
