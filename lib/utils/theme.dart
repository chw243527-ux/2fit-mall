import 'package:flutter/material.dart';

/// 2FIT Mall - Refined Minimal Design System
/// Clean, modern, premium feel
/// - Deep Charcoal primary with warm white surfaces
/// - Soft shadows and gentle radii
/// - Refined typography with balanced spacing

/// 2FIT Mall - Refined Minimal Design System
/// Clean, modern, premium feel
/// - Deep Charcoal primary with warm white surfaces
/// - Soft shadows and gentle radii
/// - Refined typography with balanced spacing
class AppColors {
  // ── Core ──
  static const Color primary      = Color(0xFF111111); // editorial black
  static const Color primaryLight = Color(0xFF292929); // charcoal
  static const Color accent       = Color(0xFFD86442); // restrained brand accent
  static const Color accentOrange = accent;
  static const Color accentGold   = Color(0xFFB8B5AE); // neutral marker

  // ── Background ──
  static const Color background   = Color(0xFFF6F5F2); // warm off-white
  static const Color surface      = Color(0xFFFFFFFF); // pure white cards
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color surfaceGray  = Color(0xFFEDECE8); // subtle warm gray

  // ── Text ──
  static const Color textPrimary   = Color(0xFF161616);
  static const Color textSecondary = Color(0xFF66645F);
  static const Color textHint      = Color(0xFFAAA8A2);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // ── Border / Divider ──
  static const Color border  = Color(0xFFE1DFD9);
  static const Color divider = Color(0xFFEAE8E2);

  // ── Status ──
  static const Color success = Color(0xFF00A651);
  static const Color error   = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  static const Color info    = Color(0xFF2979FF);

  // ── Category ──
  static const Color catTop       = primary;
  static const Color catBottom    = primary;
  static const Color catSet       = primary;
  static const Color catOuterwear = primary;
  static const Color catAccessory = primary;

  // ── Gradient ──
  static const List<Color> primaryGradient = [Color(0xFF111111), Color(0xFF292929)];
  static const List<Color> accentGradient  = [Color(0xFFD86442), Color(0xFFB74E31)];
  static const List<Color> heroGradient    = [Color(0xFF0D0D0D), Color(0xFF252525)];
}

class AppTheme {
  // 쇼핑몰 전체 폰트패밀리 상수 (Pretendard Variable)
  static const String fontFamily = 'Pretendard Variable';

  // ── 반응형 TextTheme ────────────────────────────────────────
  // 기기 너비에 따라 폰트 크기가 자동 조정됩니다.
  // 모바일(< 600): 기준, 태블릿(600~899): ×1.05, PC(≥ 900): ×1.10
  static TextTheme responsiveTextTheme(double screenWidth) {
    final double s = screenWidth < 600
        ? 1.00   // 모바일
        : screenWidth < 900
            ? 1.05   // 태블릿
            : 1.10;  // PC

    return TextTheme(
      // 대형 제목 (헤로 배너, 섹션 제목)
      displayLarge:  _ts(30 * s, FontWeight.w900, -0.9),
      displayMedium: _ts(26 * s, FontWeight.w900, -0.7),
      displaySmall:  _ts(22 * s, FontWeight.w800, -0.5),
      // 화면 제목
      headlineLarge:  _ts(20 * s, FontWeight.w800, -0.4),
      headlineMedium: _ts(18 * s, FontWeight.w700, -0.3),
      headlineSmall:  _ts(16 * s, FontWeight.w700, -0.2),
      // AppBar / 카드 제목
      titleLarge:  _ts(16 * s, FontWeight.w700, -0.2),
      titleMedium: _ts(14 * s, FontWeight.w600, -0.1),
      titleSmall:  _ts(12 * s, FontWeight.w600,  0.0),
      // 본문
      bodyLarge:   _ts(15 * s, FontWeight.w400,  0.0),
      bodyMedium:  _ts(14 * s, FontWeight.w400,  0.0),
      bodySmall:   _ts(12 * s, FontWeight.w400,  0.0),
      // 라벨 (버튼, 탭, 뱃지)
      labelLarge:  _ts(13 * s, FontWeight.w700, -0.1),
      labelMedium: _ts(11 * s, FontWeight.w600,  0.0),
      labelSmall:  _ts(10 * s, FontWeight.w500,  0.0),
    );
  }

  static TextStyle _ts(double size, FontWeight weight, double ls) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: ls,
    color: AppColors.textPrimary,
  );

  static ThemeData lightTheme({double screenWidth = 390}) {
    final textTheme = responsiveTextTheme(screenWidth);
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: textTheme,
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
          fontFamily: 'Pretendard Variable',
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
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
          borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
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
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // ── Input: clean, pill-soft border ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
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
          fontFamily: 'Pretendard Variable',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Pretendard Variable',
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
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
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
