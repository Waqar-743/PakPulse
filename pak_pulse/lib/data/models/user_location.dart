/// The user's primary city, captured once during onboarding and stored in
/// SharedPreferences. Drives weather, map centering, and alert scoping.
class UserLocation {
  final String city;
  final double lat;
  final double lng;

  /// true when the city was auto-detected from device GPS, false when the
  /// user picked it manually.
  final bool fromGps;

  const UserLocation({
    required this.city,
    required this.lat,
    required this.lng,
    this.fromGps = false,
  });

  UserLocation copyWith({
    String? city,
    double? lat,
    double? lng,
    bool? fromGps,
  }) =>
      UserLocation(
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        fromGps: fromGps ?? this.fromGps,
      );

  @override
  bool operator ==(Object other) =>
      other is UserLocation &&
      other.city == city &&
      other.lat == lat &&
      other.lng == lng;

  @override
  int get hashCode => Object.hash(city, lat, lng);
}
