/// Major Pakistani cities with coordinates. Used by the location onboarding
/// for manual city selection and for nearest-city resolution when GPS is
/// granted. Keeping this local avoids a reverse-geocoding API dependency.
class PakistanCity {
  final String name;
  final double lat;
  final double lng;
  const PakistanCity(this.name, this.lat, this.lng);
}

class PakistanCities {
  PakistanCities._();

  static const List<PakistanCity> all = [
    PakistanCity('Islamabad', 33.6844, 73.0479),
    PakistanCity('Rawalpindi', 33.5651, 73.0169),
    PakistanCity('Lahore', 31.5204, 74.3587),
    PakistanCity('Karachi', 24.8607, 67.0011),
    PakistanCity('Faisalabad', 31.4504, 73.1350),
    PakistanCity('Multan', 30.1575, 71.5249),
    PakistanCity('Peshawar', 34.0151, 71.5249),
    PakistanCity('Quetta', 30.1798, 66.9750),
    PakistanCity('Hyderabad', 25.3960, 68.3578),
    PakistanCity('Sialkot', 32.4945, 74.5229),
    PakistanCity('Gujranwala', 32.1877, 74.1945),
    PakistanCity('Bahawalpur', 29.3956, 71.6836),
    PakistanCity('Sargodha', 32.0836, 72.6711),
    PakistanCity('Sukkur', 27.7052, 68.8574),
    PakistanCity('Abbottabad', 34.1688, 73.2215),
    PakistanCity('Mardan', 34.1989, 72.0231),
    PakistanCity('Mingora', 34.7795, 72.3614),
    PakistanCity('Jacobabad', 28.2769, 68.4514),
    PakistanCity('Murree', 33.9070, 73.3943),
    PakistanCity('Gujrat', 32.5731, 74.0789),
  ];

  /// The default city used if onboarding is ever skipped without a choice.
  static const PakistanCity fallback =
      PakistanCity('Islamabad', 33.6844, 73.0479);
}
