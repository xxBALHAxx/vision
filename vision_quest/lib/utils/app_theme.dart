import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette spatiale bioluminescente ──
  static const Color bgDeep       = Color(0xFF0A0E2E);
  static const Color bgCard       = Color(0xFF141842);
  static const Color bgSurface    = Color(0xFF1E2456);
  static const Color accentCyan   = Color(0xFF00E5FF);
  static const Color accentGreen  = Color(0xFF39FF14);
  static const Color accentPurple = Color(0xFF9B59FF);
  static const Color accentGold   = Color(0xFFFFD700);
  static const Color accentRed    = Color(0xFFFF3B5C);
  static const Color textPrimary  = Color(0xFFEEF2FF);
  static const Color textSecond   = Color(0xFF8892C8);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E2E), Color(0xFF1A0A3E), Color(0xFF0A1A3E)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0090FF)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF00CC44)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: accentCyan,
      secondary: accentGreen,
      tertiary: accentPurple,
      surface: bgCard,
      onPrimary: bgDeep,
      onSecondary: bgDeep,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48, fontWeight: FontWeight.w900,
        color: textPrimary, letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: textPrimary, letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecond),
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: bgDeep, letterSpacing: 1,
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentCyan,
        foregroundColor: bgDeep,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    ),
  );
}

class AppStrings {
  static const appName = 'Vision Quest';
  static const tagline = 'Entraîne tes yeux, deviens un héros !';
}
