import 'package:flutter/material.dart';

/// 2FIT Mall - Refined Minimal Design System
/// Clean, modern, premium feel
/// - Deep Charcoal primary with warm white surfaces
/// - Soft shadows and gentle radii
/// - Refined typography with balanced spacing
class AppColors {
  // ── Core ──
  static const Color primary      = Color(0xFF1A1A2E); // deep navy-charcoal
  static const Color primaryLight = Color(0xFF2D2D44);
  static const Color accent       = Color(0xFFE53935); // refined red
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGold   = Color(0xFFFFD600);

  // ── Background ──
  static const Color background   = Color(0xFFF8F8FA); // warm off-white
  static const Color surface      = Color(0xFFFFFFFF); // pure white cards
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color surfaceGray  = Color(0xFFF2F2F6); // subtle section bg

  // ── Text ──
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textHint      = Color(0xFFB0B0C0);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // ── Border / Divider ──
  static const Color border  = Color(0xFFEAEAF0);
  static const Color divider = Color(0xFFF0F0F5);

  // ── Status ──
  static const Color success = Color(0xFF00A651);
  static const Color error   = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  static const Color info    = Color(0xFF2979FF);

  // ── Category ──
  static const Color catTop       = Color(0xFF1A1A2E);
  static const Color catBottom    = Color(0xFF1A1A2E);
  static const Color catSet       = Color(0xFF1A1A2E);
  static const Color catOuterwear = Color(0xFF1A1A2E);
  static const Color catAccessory = Color(0xFF1A1A2E);

  // ── Gradient ──
  static const List<Color> primaryGradient = [Color(0xFF1A1A2E), Color(0xFF2D2D44)];
  static const List<Color> accentGradient  = [Color(0xFFE53935), Color(0xFFC62828)];
  static const List<Color> heroGradient    = [Color(0xFF0F0F1E), Color(0xFF1A1A2E)];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar: crisp white, ultra-thin bottom line ──
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        shadowColor: Color(0x14000000),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card: soft shadow, refined radius ──
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shadowColor: const Color(0x10000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton: deep fill, smooth radius ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── OutlinedButton: refined border ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Input: clean, pill-soft border ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Divider: feather-light ──
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.8,
        space: 0,
      ),

      // ── BottomNavigationBar: white + subtle top border ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Chip: soft pill shape ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceGray,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
