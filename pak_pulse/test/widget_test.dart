// Smoke tests for PAK·PULSE.
//
// These exercise the light/dark theme toggle wiring without booting the full
// app (which would require dotenv assets and would leave splash timers
// pending). See `app.dart` for how themeModeProvider drives the UI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pak_pulse/core/theme/app_colors.dart';
import 'package:pak_pulse/providers.dart';

void main() {
  test('themeModeProvider defaults to dark', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('themeModeProvider can be toggled to light and back', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    expect(container.read(themeModeProvider), ThemeMode.light);

    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('AppColors.applyTheme swaps the palette for each mode', () {
    AppColors.applyTheme(isLight: true);
    expect(AppColors.isLight, isTrue);
    final lightBg = AppColors.backgroundBase;

    AppColors.applyTheme(isLight: false);
    expect(AppColors.isLight, isFalse);
    final darkBg = AppColors.backgroundBase;

    expect(lightBg, isNot(equals(darkBg)));

    // Leave the palette in its default (dark) state for other tests.
    AppColors.applyTheme(isLight: false);
  });
}
