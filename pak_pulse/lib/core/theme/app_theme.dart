import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the Material 3 [ThemeData] for PAK·PULSE.
///
/// Both [light] and [dark] read from [AppColors], whose theme-aware fields are
/// mutated by `AppColors.applyTheme()` before this is called (see `app.dart`).
/// Always request the getter that matches the active palette.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(brightness: Brightness.dark);
  static ThemeData get light => _build(brightness: Brightness.light);

  static ThemeData _build({required Brightness brightness}) {
    final isLight = brightness == Brightness.light;

    // Built from the factory (fills every M3 slot) and then overridden, so it
    // stays valid across Flutter versions regardless of constructor changes.
    final base = isLight ? const ColorScheme.light() : const ColorScheme.dark();
    final colorScheme = base.copyWith(
      primary: AppColors.critical,
      onPrimary: Colors.white,
      secondary: AppColors.signalBlue,
      onSecondary: Colors.white,
      tertiary: AppColors.protestViolet,
      onTertiary: Colors.white,
      error: AppColors.critical,
      onError: Colors.white,
      surface: AppColors.backgroundBase,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderSubtle,
      outlineVariant: AppColors.borderSubtle,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.backgroundBase,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      canvasColor: AppColors.backgroundBase,
      cardColor: AppColors.surfaceCard,
      dividerColor: AppColors.borderSubtle,
      iconTheme: IconThemeData(color: AppColors.textSecondary),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          displayMedium: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textTertiary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.critical.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.signalBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.signalBlue
              : (isLight ? Colors.white : AppColors.textSecondary),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.signalBlue.withOpacity(0.4)
              : AppColors.borderSubtle,
        ),
        trackOutlineColor:
            WidgetStateProperty.all(AppColors.borderSubtle),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.borderSubtle),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.signalBlue,
        linearTrackColor: AppColors.borderSubtle,
        circularTrackColor: AppColors.borderSubtle,
      ),
    );
  }
}
