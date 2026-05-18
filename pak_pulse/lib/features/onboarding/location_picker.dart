import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/pakistan_cities.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_location.dart';
import '../../data/services/location_service.dart';

/// Shared location-capture UI used by onboarding and by the Settings
/// "Change city" sheet.
///
/// Offers GPS auto-detection (via the geolocator package) and, as a fallback,
/// a searchable list of major Pakistani cities for manual entry.
class LocationPicker extends StatefulWidget {
  /// Invoked once the user has chosen — or auto-detected — their city.
  final void Function(UserLocation location) onPicked;

  const LocationPicker({super.key, required this.onPicked});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _detecting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() => _detecting = true);
    final detected = await LocationService.detectViaGps();
    if (!mounted) return;
    setState(() => _detecting = false);
    if (detected != null) {
      widget.onPicked(detected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceCard,
          content: Text(
            'Location access denied — pick your city below',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }
  }

  void _pickCity(PakistanCity city) {
    widget.onPicked(UserLocation(
      city: city.name,
      lat: city.lat,
      lng: city.lng,
      fromGps: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cities = PakistanCities.all
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Use my location ──────────────────────────────────────────────
        GestureDetector(
          onTap: _detecting ? null : _useGps,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.signalBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_detecting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  const Icon(Icons.my_location,
                      size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  _detecting ? 'Detecting…' : 'Use my location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ── Manual city search ───────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search your city…',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── City list ────────────────────────────────────────────────────
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cities.length,
            itemBuilder: (_, i) {
              final city = cities[i];
              return InkWell(
                onTap: () => _pickCity(city),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.location_city,
                          size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Text(
                        city.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
