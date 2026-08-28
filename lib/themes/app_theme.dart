import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final text = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceSoft,
        onPrimary: AppColors.primaryDeep,
        onSurface: AppColors.textLight,
      ),
      textTheme: text.apply(
        bodyColor: AppColors.textLight,
        displayColor: AppColors.textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.accent,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        labelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
      inputDecorationTheme: _inputTheme(true),
    );
  }

  static ThemeData light() {
    final text = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSurface: AppColors.textDark,
      ),
      textTheme: text.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: _inputTheme(false),
    );
  }

  static InputDecorationTheme _inputTheme(bool dark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
      hintStyle: TextStyle(color: dark ? Colors.white54 : AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE4ECF2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE4ECF2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    );
  }
}
