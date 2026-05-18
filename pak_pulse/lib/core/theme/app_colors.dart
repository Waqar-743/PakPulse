import 'package:flutter/material.dart';

/// AppColors holds the palette. Most fields are theme-aware: they switch
/// values when `applyTheme(isLight: bool)` is called. Accent colors
/// (severity, agent, crisis-type) remain const because they read identically
/// on both light and dark backgrounds.
///
/// Theme-aware fields are deliberately NOT `const` so they can be mutated at
/// runtime by the light-mode toggle in Settings.
class AppColors {
  AppColors._();

  // ── Theme-aware (mutable) ──────────────────────────────────────────────────

  // Dark defaults (Phase 1 design system)
  static Color backgroundBase = const Color(0xFF0A0E1A);
  static Color surfaceElevated = const Color(0xFF131826);
  static Color surfaceCard = const Color(0xFF1A2030);
  static Color borderSubtle = const Color(0xFF2A3142);

  static Color textPrimary = const Color(0xFFF5F7FA);
  static Color textSecondary = const Color(0xFF94A3B8);
  static Color textTertiary = const Color(0xFF64748B);

  // ── Accent colors (constant across themes) ─────────────────────────────────

  // Severity
  static const Color critical = Color(0xFFFF3B5C);
  static const Color high = Color(0xFFFF8A3D);
  static const Color moderate = Color(0xFFFFD23D);
  static const Color low = Color(0xFF3DDC97);

  // Crisis types / agents
  static const Color signalBlue = Color(0xFF4D9FFF);
  static const Color protestViolet = Color(0xFFB84DFF);
  static const Color heatOrange = Color(0xFFFF6B3D);

  // Aliases
  static const Color floodColor = signalBlue;
  static const Color heatwaveColor = heatOrange;
  static const Color protestColor = protestViolet;

  // Agent colors
  static const Color agentSignal = signalBlue;
  static const Color agentDetection = protestViolet;
  static const Color agentSeverity = high;
  static const Color agentAction = critical;

  // ── Theme application ──────────────────────────────────────────────────────

  static bool _isLight = false;
  static bool get isLight => _isLight;

  static void applyTheme({required bool isLight}) {
    _isLight = isLight;
    if (isLight) {
      backgroundBase = const Color(0xFFF5F7FA);
      surfaceElevated = const Color(0xFFFFFFFF);
      surfaceCard = const Color(0xFFEDF1F7);
      borderSubtle = const Color(0xFFD6DCE6);
      textPrimary = const Color(0xFF0A0E1A);
      textSecondary = const Color(0xFF3F4A5C);
      textTertiary = const Color(0xFF6B7689);
    } else {
      backgroundBase = const Color(0xFF0A0E1A);
      surfaceElevated = const Color(0xFF131826);
      surfaceCard = const Color(0xFF1A2030);
      borderSubtle = const Color(0xFF2A3142);
      textPrimary = const Color(0xFFF5F7FA);
      textSecondary = const Color(0xFF94A3B8);
      textTertiary = const Color(0xFF64748B);
    }
  }
}
