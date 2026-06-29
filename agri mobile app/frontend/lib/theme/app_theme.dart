// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── NEW: Deep indigo + cyan + electric palette ──────────────────
  static const Color primary = Color(0xFF4F6EF7); // electric indigo
  static const Color primaryLight = Color(0xFF7B93FF);
  static const Color primaryDark = Color(0xFF1A2E8A);
  static const Color accent = Color(0xFF00D4FF); // electric cyan
  static const Color accentLight = Color(0xFF7EEEFF);
  static const Color danger = Color(0xFFFF4F6E); // vivid coral-red
  static const Color dangerLight = Color(0xFFFF8FA3);
  static const Color warning = Color(0xFFFFB547); // amber
  static const Color success = Color(0xFF00E5A0); // mint green
  static const Color successDark = Color(0xFF00A371);
  static const Color info = Color(0xFF4F6EF7);

  // ── Backgrounds ──────────────────────────────────────────────────
  static const Color bg = Color(0xFF0B0D1A); // near-black navy
  static const Color bgCard = Color(0xFF141729);
  static const Color bgCardLight = Color(0xFF1C2040);
  static const Color bgSurface = Color(0xFF10132B);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEAECFF);
  static const Color textSecondary = Color(0xFF8B91CC);
  static const Color textMuted = Color(0xFF454870);

  // ── Chart ────────────────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF4F6EF7),
    Color(0xFF00D4FF),
    Color(0xFF00E5A0),
    Color(0xFFFFB547),
    Color(0xFFFF4F6E),
    Color(0xFFBF6EFF),
    Color(0xFFFF8C42),
    Color(0xFF00C4B4),
  ];
}

class AppTheme {
  static ThemeData get light {
    return dark.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.danger,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCard,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textSecondary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          bodySmall: TextStyle(color: AppColors.textMuted),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF252A52), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: const Color(0xFF252A52),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }
}
