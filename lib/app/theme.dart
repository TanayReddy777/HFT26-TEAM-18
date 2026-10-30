import 'package:flutter/material.dart';

class ResQTheme {
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color surfaceCard = Color(0xFF1E293B); // Slate 800
  static const Color surfaceBorder = Color(0xFF334155); // Slate 700

  // Emergency Accents
  static const Color sosRed = Color(0xFFEF4444); // Critical P0
  static const Color warningOrange = Color(0xFFF97316); // Urgent P1 / Hazard P2
  static const Color safeGreen = Color(0xFF10B981); // Resolved / Safe
  static const Color meshCyan = Color(0xFF06B6D4); // Mesh P2P
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: meshCyan,
        secondary: warningOrange,
        error: sosRed,
        surface: surfaceCard,
        onSurface: textPrimary,
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
        elevation: 4,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
