import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/pakistan_cities.dart';
import '../models/user_location.dart';

/// Persists and resolves the user's primary city.
///
/// - GPS permission + position is handled via the `geolocator` package.
/// - Reverse geocoding is done locally against [PakistanCities] (nearest city)
///   so no extra geocoding API or key is required.
/// - The chosen location is stored in SharedPreferences and never asked again.
class LocationService {
  LocationService._();

  static const _kCity = 'user_city';
  static const _kLat = 'user_lat';
  static const _kLng = 'user_lng';
  static const _kFromGps = 'user_loc_from_gps';
  static const _kLocationSet = 'location_set';

  /// Whether a location has already been captured. When true, onboarding must
  /// never prompt for it again.
  static Future<bool> isLocationSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLocationSet) ?? false;
  }

  /// Loads the stored location, or null if none was ever set.
  static Future<UserLocation?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kLocationSet) ?? false)) return null;
    final city = prefs.getString(_kCity);
    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);
    if (city == null || lat == null || lng == null) return null;
    return UserLocation(
      city: city,
      lat: lat,
      lng: lng,
      fromGps: prefs.getBool(_kFromGps) ?? false,
    );
  }

  /// Stores the location permanently.
  static Future<void> save(UserLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCity, location.city);
    await prefs.setDouble(_kLat, location.lat);
    await prefs.setDouble(_kLng, location.lng);
    await prefs.setBool(_kFromGps, location.fromGps);
    await prefs.setBool(_kLocationSet, true);
  }

  /// Requests GPS permission and resolves the device position to the nearest
  /// known Pakistani city. Returns null if permission is denied or the device
  /// has location services switched off.
  static Future<UserLocation?> detectViaGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final nearest = nearestCity(position.latitude, position.longitude);
      // Keep the precise device coordinates — only the label is snapped.
      return UserLocation(
        city: nearest.name,
        lat: position.latitude,
        lng: position.longitude,
        fromGps: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the [PakistanCity] geographically closest to the given point.
  static PakistanCity nearestCity(double lat, double lng) {
    PakistanCity best = PakistanCities.fallback;
    double bestMeters = double.infinity;
    for (final c in PakistanCities.all) {
      final d = Geolocator.distanceBetween(lat, lng, c.lat, c.lng);
      if (d < bestMeters) {
        bestMeters = d;
        best = c;
      }
    }
    return best;
  }
}
