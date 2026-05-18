import 'package:latlong2/latlong.dart';

class IslamabadSectors {
  IslamabadSectors._();

  static const Map<String, LatLng> sectors = {
    // G sectors
    'G-5': LatLng(33.7294, 73.0931),
    'G-6': LatLng(33.7238, 73.0850),
    'G-7': LatLng(33.7172, 73.0775),
    'G-8': LatLng(33.7050, 73.0631),
    'G-9': LatLng(33.6994, 73.0478),
    'G-10': LatLng(33.6900, 73.0228),
    'G-10 Markaz': LatLng(33.6900, 73.0228),
    'G-11': LatLng(33.6850, 72.9980),
    'G-12': LatLng(33.6800, 72.9740),
    'G-13': LatLng(33.6750, 72.9500),
    'G-14': LatLng(33.6700, 72.9260),
    'G-15': LatLng(33.6650, 72.9020),

    // F sectors
    'F-5': LatLng(33.7294, 73.0678),
    'F-6': LatLng(33.7294, 73.0503),
    'F-7': LatLng(33.7216, 73.0503),
    'F-8': LatLng(33.7216, 73.0228),
    'F-9': LatLng(33.7216, 72.9980),
    'F-10': LatLng(33.7216, 72.9740),
    'F-11': LatLng(33.7216, 72.9500),

    // I sectors
    'I-8': LatLng(33.6722, 73.0631),
    'I-9': LatLng(33.6600, 73.0631),
    'I-10': LatLng(33.6478, 73.0631),
    'I-11': LatLng(33.6356, 73.0631),
    'I-12': LatLng(33.6234, 73.0631),
    'I-13': LatLng(33.6112, 73.0631),
    'I-14': LatLng(33.5990, 73.0631),

    // Key locations
    'Blue Area': LatLng(33.7215, 73.0644),
    'Faizabad': LatLng(33.6938, 73.0651),
    'Faizabad Interchange': LatLng(33.6938, 73.0651),
    'Saddar Rawalpindi': LatLng(33.5993, 73.0551),
    '6th Road': LatLng(33.5950, 73.0478),
    'Murree Road': LatLng(33.6300, 73.0800),
    'Committee Chowk': LatLng(33.5847, 73.0479),
  };

  static LatLng? resolve(String sectorName) {
    final key = sectors.keys.firstWhere(
      (k) => k.toLowerCase() == sectorName.toLowerCase(),
      orElse: () => '',
    );
    return key.isEmpty ? null : sectors[key];
  }
}
