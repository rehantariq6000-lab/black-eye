import 'package:flutter/material.dart';

/// The colours used across the app, taken from the Black Eye logo:
/// a near-black background, silver metallic tones, and a purple accent.
class AppColors {
  static const Color background = Color(0xFF0B0B0D); // almost black
  static const Color surface = Color(0xFF17171C); // panels / cards
  static const Color accent = Color(0xFF8F7BE8); // logo purple ("EYE")
  static const Color silver = Color(0xFFC7C7D1); // logo silver
  static const Color textMuted = Color(0xFF9A9AA6);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.silver,
        side: const BorderSide(color: AppColors.accent),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : null,
      ),
    ),
  );
}
