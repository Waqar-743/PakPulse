class MockAgentResponses {
  const MockAgentResponses();

  Map<String, dynamic> signalResponse(String rawText) => {
        'language': _detectLanguage(rawText),
        'sector': _detectSector(rawText),
        'lat_hint': null,
        'lng_hint': null,
        'crisis_hint': _detectCrisis(rawText),
        'severity_hint': 'high',
        'extracted_entities': _extractEntities(rawText),
        'confidence': 0.88,
        'reasoning':
            'Signal processed in DEMO_MODE. Language detected from keyword analysis. Sector resolved from IslamabadSectors lookup. Crisis type inferred from domain vocabulary.',
      };

  Map<String, dynamic> detectionResponse(String crisisHint) => {
        'is_new_crisis': true,
        'crisis_type': crisisHint,
        'cluster_id': 'demo-cluster-${DateTime.now().millisecondsSinceEpoch}',
        'signal_count_in_cluster': 3,
        'confidence': 0.85,
        'reasoning':
            'Cluster threshold met: 3+ signals from same sector within 2-hour window. DEMO_MODE active — using mock clustering logic.',
      };

  Map<String, dynamic> severityResponse(String crisisType) => {
        'severity': 'high',
        'rsi_score': 74,
        'affected_radius_meters': 1000,
        'casualty_risk': 'moderate',
        'summary_en':
            'Crisis detected and assessed in DEMO_MODE. Risk score calculated using signal count and source weighting.',
        'summary_ur':
            'بحران کا پتہ لگایا گیا ہے اور خطرے کی سطح کا اندازہ لگایا گیا ہے۔ سگنل کی تعداد اور ذرائع کی بنیاد پر خطرے کا اسکور حساب کیا گیا ہے۔',
        'reasoning':
            'RSI computed: base 40 + source multipliers + Pakistan context factors. DEMO_MODE active.',
      };

  Map<String, dynamic> actionResponse(String sector, String crisisType) => {
        'actions': [
          {
            'priority': 1,
            'type': 'dispatch_rescue',
            'title': 'Deploy Rescue 1122 — $sector',
            'description':
                'Dispatch 2 rescue units with 8 personnel to $sector for immediate crisis response.',
            'target_agency': 'Rescue 1122 Islamabad',
            'payload': {'sector': sector, 'units': 2},
            'estimated_impact':
                'Life safety response within 12 minutes. Estimated 20 people assisted.',
          },
          {
            'priority': 2,
            'type': 'traffic_reroute',
            'title': 'Activate Alternate Route — $sector',
            'description':
                'Divert traffic away from $sector via Service Road Eastern. Deploy ITP officers.',
            'target_agency': 'Islamabad Traffic Police (ITP)',
            'payload': {'blocked': sector, 'alternate': 'Service Road Eastern'},
            'estimated_impact': 'Traffic clearance within 20 minutes. 30,000 commuters rerouted.',
          },
          {
            'priority': 3,
            'type': 'citizen_alert_sms',
            'title': 'Emergency SMS Alert — $sector Residents',
            'description':
                'Send bilingual SMS alert to residents of $sector warning of $crisisType crisis.',
            'target_agency': 'NDMA Emergency Communication Cell',
            'payload': {'sector': sector, 'recipients': 45000},
            'estimated_impact': '45,000 residents notified within 5 minutes.',
          },
        ],
        'reasoning':
            'Three-tier response: life safety first, traffic management second, public communication third. DEMO_MODE active — using mock action generation.',
      };

  String _detectLanguage(String text) {
    if (RegExp(r'[؀-ۿ]').hasMatch(text)) return 'urdu';
    final romanUrduWords = ['mein', 'hai', 'ho', 'gaya', 'pani', 'garmi', 'dharna'];
    for (final word in romanUrduWords) {
      if (text.toLowerCase().contains(word)) return 'roman_ur';
    }
    return 'english';
  }

  String? _detectSector(String text) {
    final sectors = ['G-10', 'G-11', 'G-9', 'F-7', 'F-8', 'I-8', 'I-9', 'Faizabad', 'Blue Area'];
    for (final s in sectors) {
      if (text.contains(s)) return s;
    }
    return null;
  }

  String _detectCrisis(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('pani') || lower.contains('flood') || lower.contains('baarish')) {
      return 'flood';
    }
    if (lower.contains('garmi') || lower.contains('heat') || lower.contains('degree')) {
      return 'heatwave';
    }
    if (lower.contains('dharna') || lower.contains('block') || lower.contains('protest')) {
      return 'protest';
    }
    return 'none';
  }

  List<String> _extractEntities(String text) {
    final entities = <String>[];
    final keywords = {
      'pani': 'water/flood',
      'garmi': 'heat',
      'dharna': 'protest/sit-in',
      'gaari': 'vehicle',
      'madad': 'help_request',
      'band': 'blocked',
      'G-10': 'sector_G10',
      'Faizabad': 'location_faizabad',
    };
    for (final entry in keywords.entries) {
      if (text.toLowerCase().contains(entry.key.toLowerCase())) {
        entities.add(entry.value);
      }
    }
    return entities;
  }
}
