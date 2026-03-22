import 'package:flutter/material.dart';

/// Nike-inspired design system
/// - Pure Black (#111111) + Pure White (#FFFFFF) as primary palette
/// - Red (#FF0000) as accent
/// - Bold, condensed typography
/// - Sharp corners (radius 0–4px for key elements)
class AppColors {
  // ── Core ──
  static const Color primary     = Color(0xFF111111); // near-black
  static const Color primaryLight= Color(0xFF2B2B2B);
  static const Color accent      = Color(0xFFFF0000); // Nike red
  static const Color accentOrange= Color(0xFFFF6B35);
  static const Color accentGold  = Color(0xFFFFD600);

  // ── Background ──
  static const Color background  = Color(0xFFFFFFFF); // pure white bg
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF5F5F5); // light gray section bg

  // ── Text ──
  static const Color textPrimary   = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint      = Color(0xFFAAAAAA);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // ── Border / Divider ──
  static const Color border  = Color(0xFFE5E5E5);
  static const Color divider = Color(0xFFEEEEEE);

  // ── Status ──
  static const Color success = Color(0xFF00A651);
  static const Color error   = Color(0xFFFF0000);
  static const Color warning = Color(0xFFFFD600);
  static const Color info    = Color(0xFF2196F3);

  // ── Category (monochrome Nike style) ──
  static const Color catTop       = Color(0xFF111111);
  static const Color catBottom    = Color(0xFF111111);
  static const Color catSet       = Color(0xFF111111);
  static const Color catOuterwear = Color(0xFF111111);
  static const Color catAccessory = Color(0xFF111111);

  // ── Gradient ──
  static const List<Color> primaryGradient = [Color(0xFF111111), Color(0xFF333333)];
  static const List<Color> accentGradient  = [Color(0xFFFF0000), Color(0xFFCC0000)];
  static const List<Color> heroGradient    = [Color(0xFF0D0D0D), Color(0xFF1C1C1C)];
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

      // ── AppBar: pure white, no shadow, bold centered title ──
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.white,
      ),

      // ── Card: flat, minimal border, sharp corner ──
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton: black fill, white text, sharp rect ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ── OutlinedButton: black border, sharp ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Input: clean, thin border ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
