import 'package:latlong2/latlong.dart';

import '../../core/constants/islamabad_sectors.dart';

class GeocodingTool {
  GeocodingTool._();

  static String normalize(String text) {
    var t = text.trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    final substitutions = <String, String>{
      'mein': 'in',
      'hai': 'is',
      'gaya': 'happened',
      'pani': 'water',
      'baarish': 'rain',
      'garmi': 'heat',
      'dharna': 'protest',
      'gaariyan': 'vehicles',
      'gaari': 'vehicle',
      'phans': 'stuck',
      'madad': 'help',
      'band': 'blocked',
      'ho': 'is',
      'rasta': 'road',
      'rasta band': 'road blocked',
    };
    var lowered = t.toLowerCase();
    for (final entry in substitutions.entries) {
      lowered = lowered.replaceAll(entry.key, entry.value);
    }
    return lowered;
  }

  static LatLng? resolveSector(String? sector) {
    if (sector == null || sector.isEmpty) return null;
    return IslamabadSectors.resolve(sector);
  }

  static String? extractSector(String rawText) {
    final t = rawText.toUpperCase();
    for (final key in IslamabadSectors.sectors.keys) {
      if (t.contains(key.toUpperCase())) return key;
    }
    if (t.contains('JACOBABAD')) return 'Jacobabad District';
    return null;
  }
}
